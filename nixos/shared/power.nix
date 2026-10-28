{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  display = config.laptop.display;

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

    # niri-session normally sets WAYLAND_DISPLAY, but fall back to the
    # first compositor socket if a service starts without it.
    if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
      for socket in "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/wayland-*; do
        [ -S "$socket" ] || continue
        export WAYLAND_DISPLAY="$(basename "$socket")"
        break
      done
    fi

    ${config.programs.niri.package}/bin/niri msg output ${display.output} mode "$MODE" 2>/dev/null || true
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
    else
      BRIGHTNESS="${brightnessFor "1"}"
      MODE="${modeFor "1"}"
      PROFILE="performance"
    fi

    if [ -n "$BRIGHTNESS" ] && [ -w "$BACKLIGHT" ]; then
      echo "$BRIGHTNESS" > "$BACKLIGHT" || true
    fi

    ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set "$PROFILE" 2>/dev/null || true

    # If niri is already running, apply the refresh-rate change immediately.
    # At boot the user service below does it after login.
    RUNTIME_DIR="/run/user/$(id -u ${username})"
    if [ -n "$MODE" ] && [ -d "$RUNTIME_DIR" ]; then
      for socket in "$RUNTIME_DIR"/wayland-*; do
        [ -S "$socket" ] || continue
        XDG_RUNTIME_DIR="$RUNTIME_DIR" WAYLAND_DISPLAY="$(basename "$socket")" \
          ${config.programs.niri.package}/bin/niri msg output ${display.output} mode "$MODE" 2>/dev/null || true
        break
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

    display = lib.mkOption {
      type = lib.types.submodule {
        options = {
          output = lib.mkOption {
            type = lib.types.str;
            default = "eDP-1";
            description = "niri output name for the internal panel.";
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
      after = [ "power-profiles-daemon.service" ];
      wants = [ "power-profiles-daemon.service" ];
      wantedBy = [ "multi-user.target" ];
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
