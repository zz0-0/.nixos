{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  display = config.laptop.display;
  wifi = config.laptop.wifi.interface;

  adapter = "/sys/class/power_supply/${config.laptop.power.adapter}/online";
  backlight = "/sys/class/backlight/${display.backlight}/brightness";

  # Empty strings mean "do not touch this setting on this host".
  brightnessFor =
    online:
    let
      value = if online == "0" then display.brightnessBattery else display.brightnessAC;
    in
    if value == null then "" else toString value;

  modeFor =
    online:
    let
      value = if online == "0" then display.modeBattery else display.modeAC;
    in
    if value == null then "" else value;

  # Toggle WiFi power saving with AC state. The interface is optional so
  # hosts without a configured wireless device keep the old behaviour.
  wifiPowerScript =
    if wifi == null then
      ""
    else
      ''
        if [ -d "/sys/class/net/${wifi}" ]; then
          ${pkgs.iw}/bin/iw dev ${wifi} set power_save "$WIFI_POWER" 2>/dev/null || true
        fi
      '';

  # Connector numbering is not stable on this machine: the Intel and NVIDIA
  # GPUs swap the eDP-1/eDP-2 names depending on probe order, and it flipped
  # after the 7.3.1 -> 7.3.4 update. A hardcoded name therefore works until the
  # next reboot. The configured name stays as a hint; the panel is whichever
  # internal connector niri actually reports.
  panelResolver = ''
    niri_panel_output() {
      local outputs="$1"
      if [[ "$outputs" == *"(${display.output})"* ]]; then
        printf '%s' "${display.output}"
        return 0
      fi
      if [[ "$outputs" =~ \(((eDP|LVDS)-?[0-9]+)\) ]]; then
        printf '%s' "''${BASH_REMATCH[1]}"
        return 0
      fi
      return 1
    }
  '';

  # Runs as the logged-in user, after niri has created its socket.
  niriModeScript = pkgs.writeShellScript "niri-display-power" ''
    set -eu

    ADAPTER="${adapter}"
    MODE_BAT="${modeFor "0"}"
    MODE_AC="${modeFor "1"}"

    [ -f "$ADAPTER" ] || exit 0
    if [ "$(cat "$ADAPTER")" = "0" ]; then
      MODE="$MODE_BAT"
    else
      MODE="$MODE_AC"
    fi
    [ -n "$MODE" ] || exit 0

    # `niri msg` needs NIRI_SOCKET; WAYLAND_DISPLAY alone is not enough (it
    # answers "NIRI_SOCKET is not set, are you running this within niri?").
    # The socket name carries niri's pid, so find it rather than guess.
    if [ -z "''${NIRI_SOCKET:-}" ]; then
      for sock in "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/niri.*.sock; do
        [ -S "$sock" ] || continue
        export NIRI_SOCKET="$sock"
        break
      done
    fi

    # `niri msg output <name> mode ...` exits 0 even when no such output is
    # connected — it just queues the change for later. A wrong name would
    # therefore never fail and never take effect, so resolve the panel from
    # what niri reports and fail loudly when there is none.
    ${panelResolver}
    outputs="$(${config.programs.niri.package}/bin/niri msg outputs 2>&1 || true)"
    if ! panel="$(niri_panel_output "$outputs")"; then
      echo "niri-display-power: no internal panel in niri outputs:" >&2
      printf '%s\n' "$outputs" >&2
      exit 1
    fi
    [ "$panel" = "${display.output}" ] \
      || echo "niri-display-power: panel is $panel, configured ${display.output}" >&2
    ${config.programs.niri.package}/bin/niri msg output "$panel" mode "$MODE" >/dev/null 2>&1 || true
  '';

  # Runs as root from udev / at boot. Sets brightness and power profile, and
  # tries the niri mode change if a user session is already up.
  powerStateScript = pkgs.writeShellScript "power-state-change" ''
    set -eu

    ADAPTER="${adapter}"
    BACKLIGHT="${backlight}"

    if [ -f "$ADAPTER" ] && [ "$(cat "$ADAPTER")" = "0" ]; then
      BRIGHTNESS="${brightnessFor "0"}"
      MODE="${modeFor "0"}"
      PROFILE="power-saver"
      WIFI_POWER="on"
    else
      BRIGHTNESS="${brightnessFor "1"}"
      MODE="${modeFor "1"}"
      PROFILE="performance"
      WIFI_POWER="off"
    fi

    if [ -n "$BRIGHTNESS" ] && [ -w "$BACKLIGHT" ]; then
      echo "$BRIGHTNESS" > "$BACKLIGHT" || true
    fi

    ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set "$PROFILE" 2>/dev/null || true

    ${wifiPowerScript}

    # If niri is already running, apply the refresh-rate change immediately.
    # This is the path that actually runs when the charger is plugged or
    # unplugged mid-session; the user service below only covers login.
    #
    # The IPC socket name carries niri's pid and NIRI_SOCKET is mandatory, so
    # find the socket instead of assuming the session environment is visible
    # from a system service (it is not).
    RUNTIME_DIR="/run/user/$(id -u ${username})"
    ${panelResolver}
    if [ -n "$MODE" ] && [ -d "$RUNTIME_DIR" ]; then
      for sock in "$RUNTIME_DIR"/niri.*.sock; do
        [ -S "$sock" ] || continue
        export NIRI_SOCKET="$sock"
        outputs="$(${config.programs.niri.package}/bin/niri msg outputs 2>&1 || true)"
        if panel="$(niri_panel_output "$outputs")"; then
          ${config.programs.niri.package}/bin/niri msg output "$panel" mode "$MODE" >/dev/null 2>&1 || true
          break
        fi
        # No panel in this output list: the compositor is still coming up.
        # Try the next socket instead of giving up.
      done
    fi
  '';
in
{
  options.laptop = {
    power.adapter = lib.mkOption {
      type = lib.types.str;
      default = "ADP1";
      description = "power_supply device name used for AC state.";
    };

    wifi.interface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Wireless interface used to toggle power saving on AC/battery.";
    };

    display = lib.mkOption {
      type = lib.types.submodule {
        options = {
          output = lib.mkOption {
            type = lib.types.str;
            default = "eDP-1";
            description = ''
              niri output name for the internal panel. Only a hint: the
              connector numbering swaps between eDP-1 and eDP-2 across boots,
              so the scripts fall back to the first eDP-*/LVDS* output niri
              reports when this name is not present.
            '';
          };
          backlight = lib.mkOption {
            type = lib.types.str;
            default = "intel_backlight";
            description = "Backlight device under /sys/class/backlight.";
          };
          brightnessAC = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.unsigned;
            default = null;
            description = "Backlight level on AC. null leaves brightness alone.";
          };
          brightnessBattery = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.unsigned;
            default = null;
            description = "Backlight level on battery. null leaves brightness alone.";
          };
          modeAC = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "niri output mode on AC. null leaves the mode alone.";
          };
          modeBattery = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "niri output mode on battery. null leaves the mode alone.";
          };
        };
      };
      default = { };
      description = "Display settings used by the AC/battery power-state service.";
    };
  };

  config = {
    services.upower.enable = true;

    # ── Power Profiles Daemon ──────────────────────────────────────────────
    # Switch profiles:  powerprofilesctl set power-saver|balanced|performance
    services.power-profiles-daemon.enable = true;

    # ── Intel WiFi power saving ────────────────────────────────────────────
    # i915 options are host-specific: zz2 uses the xe driver, so putting
    # i915 options here would silently do nothing on zz2.
    boot.extraModprobeConfig = ''
      options iwlwifi power_save=1
    '';

    # Disable the NMI watchdog: a small idle-power and jitter win.
    # Keep the existing 5s USB autosuspend delay (the kernel default is 2s);
    # this was deliberately made less aggressive for USB device stability.
    # The NVMe APST latency override that used to live here has been removed:
    # 200us is far below the default (100000us) and excludes the deeper,
    # lower-power APST states rather than enabling them.
    boot.kernelParams = [
      "nmi_watchdog=0"
      "usbcore.autosuspend=5"
    ];

    # ── SATA link power management ─────────────────────────────────────────
    # med_power_with_dipm saves roughly 1-1.5W on SATA drives.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"

      # Trigger the real work from a systemd service instead of running a
      # long script from udev. --no-block keeps the udev event short.
      ACTION=="add|change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="?*", RUN+="${pkgs.systemd}/bin/systemctl start --no-block power-state-change.service"
    '';

    # ── AC/battery state change ────────────────────────────────────────────
    systemd.services.power-state-change = {
      description = "Apply AC/battery power settings";
      # power-profiles-daemon.service is ordered After=multi-user.target, so
      # pulling this unit into multi-user.target creates an ordering cycle.
      # Hook into graphical.target instead (which is where PPD is wanted).
      after = [ "power-profiles-daemon.service" ];
      wants = [ "power-profiles-daemon.service" ];
      wantedBy = [ "graphical.target" ];
      path = [ pkgs.coreutils ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = powerStateScript;
      };
    };

    # Apply the display mode after niri starts. This is the missing half of
    # the old udev rule: at boot the udev event fires before niri exists, so
    # booting on battery used to leave the panel at the AC refresh rate.
    systemd.user.services.niri-display-power = {
      description = "Apply AC/battery niri display mode";
      after = [ "niri.service" ];
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = niriModeScript;
      };
    };

    # ── Brightness fixup ───────────────────────────────────────────────────
    # systemd-backlight restores the last brightness at boot, which can
    # overwrite the AC-appropriate value. Re-apply it once after restore.
    systemd.services.brightness-on-boot = {
      description = "Re-apply brightness after systemd-backlight restore";
      after = [ "systemd-backlight@backlight:${display.backlight}.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.coreutils ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "brightness-on-boot" ''
          set -eu

          ADAPTER="${adapter}"
          BACKLIGHT="${backlight}"

          [ -f "$ADAPTER" ] || exit 0
          [ -w "$BACKLIGHT" ] || exit 0

          if [ "$(cat "$ADAPTER")" = "0" ]; then
            BRIGHTNESS="${brightnessFor "0"}"
          else
            BRIGHTNESS="${brightnessFor "1"}"
          fi

          [ -n "$BRIGHTNESS" ] && echo "$BRIGHTNESS" > "$BACKLIGHT" || true
        '';
      };
    };
  };
}
