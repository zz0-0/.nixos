{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.upower.enable = true;

  # ── Power Profiles Daemon ──────────────────────────────────────────────
  # Switch profiles:  powerprofilesctl set power-saver|balanced|performance
  services.power-profiles-daemon.enable = true;

  # ── Thermald ───────────────────────────────────────────────────────────
  # Intel thermal daemon — prevents throttling.
  services.thermald.enable = true;

  # ── Intel GPU + WiFi power saving ──────────────────────────────────────
  # FBC: framebuffer compression, PSR: panel self-refresh, GuC: firmware
  # iwlwifi power_save=1: enables WiFi power management (Intel cards)
  boot.extraModprobeConfig = ''
    options i915 enable_fbc=1 enable_psr=1 enable_guc=3
    options iwlwifi power_save=1
  '';

  # ── NVMe + USB power saving ────────────────────────────────────────────
  # nvme_core: allow deeper NVMe power states (~0.5-1W savings)
  # usbcore:   5 second USB autosuspend delay (default is 2s; disabled if 0)
  boot.kernelParams = [
    "nvme_core.default_ps_max_latency_us=200"
    "usbcore.autosuspend=5"
  ];

  # ── PCI Runtime Power Management ───────────────────────────────────────
  # Enable runtime PM for all PCI devices except NVIDIA dGPU.
  # NVIDIA handles its own power management via the nvidia driver
  # (NVreg_DynamicPowerManagement).
  services.udev.extraRules = ''
    # SATA ALPM: aggressive link power management for SATA drives
    # med_power_with_dipm saves ~1-1.5W (matches Windows IRST behavior)
    ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"
  '' + ''

    # ── AC adapter change: brightness + refresh rate + trigger profile ────
    # Triggers ONLY on AC plug/unplug, NOT on battery % changes.
    # Also fires at boot (ACTION=="add|change").
    #
    # Does three things:
    # 1. Brightness (sysfs — works from udev)
    # 2. Refresh rate (niri socket — works from udev)
    # 3. Triggers systemd service for power profile (needs D-Bus)
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="?*", ACTION=="add|change", RUN+="${pkgs.writeShellScript "power-state-change" ''
      [ -f /run/systemd/shutdown ] && exit 0
      set -e
      ADAPTER="/sys/class/power_supply/ADP1/online"
      BACKLIGHT="/sys/class/backlight/intel_backlight/brightness"
      BRIGHTNESS_BAT="150"
      BRIGHTNESS_AC="496"

      # niri socket needs these to connect from udev (runs as root)
      export XDG_RUNTIME_DIR="/run/user/1000"
      export WAYLAND_DISPLAY="wayland-1"

      if [ -f "$ADAPTER" ]; then
        ONLINE=$(cat "$ADAPTER")
        if [ "$ONLINE" = "0" ]; then
          [ -w "$BACKLIGHT" ] && echo "$BRIGHTNESS_BAT" > "$BACKLIGHT" || true
          ${config.programs.niri.package}/bin/niri msg output eDP-1 mode 3200x2000@60.001 2>/dev/null || true
          # Trigger the systemd service (which calls powerprofilesctl via D-Bus)
          ${pkgs.systemd}/bin/systemctl start --no-block power-profile-switch.service 2>/dev/null || true
        else
          [ -w "$BACKLIGHT" ] && echo "$BRIGHTNESS_AC" > "$BACKLIGHT" || true
          ${config.programs.niri.package}/bin/niri msg output eDP-1 mode 3200x2000@165.000 2>/dev/null || true
          ${pkgs.systemd}/bin/systemctl start --no-block power-profile-switch.service 2>/dev/null || true
        fi
      fi
    ''}"
  '';

  # ── Power profile switching service ────────────────────────────────────
  # Called by udev on AC state change AND runs once at boot.
  # Separated from udev because powerprofilesctl needs D-Bus.
  systemd.services.power-profile-switch = {
    description = "Set power profile from AC state";
    after = [ "power-profiles-daemon.service" "multi-user.target" ];
    wants = [ "power-profiles-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.power-profiles-daemon ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "power-profile-switch" ''
        ADAPTER="/sys/class/power_supply/ADP1/online"
        if [ -f "$ADAPTER" ] && [ "$(cat "$ADAPTER")" = "0" ]; then
          powerprofilesctl set power-saver
        else
          powerprofilesctl set performance
        fi
      '';
    };
  };

  # ── Brightness fixup ───────────────────────────────────────────────────
  # systemd-backlight restores saved brightness at boot, which can overwrite
  # the udev rule's AC-appropriate value (e.g. booting on AC after a battery
  # session leaves brightness at 150 instead of 496). This service re-applies
  # the correct brightness based on current AC state.
  systemd.services.brightness-on-boot = {
    description = "Re-apply brightness after systemd-backlight restore";
    after = [ "systemd-backlight@backlight:intel_backlight.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "brightness-on-boot" ''
        ADAPTER="/sys/class/power_supply/ADP1/online"
        BACKLIGHT="/sys/class/backlight/intel_backlight/brightness"
        if [ -f "$ADAPTER" ] && [ -w "$BACKLIGHT" ]; then
          if [ "$(cat "$ADAPTER")" = "0" ]; then
            echo 150 > "$BACKLIGHT"
          else
            echo 496 > "$BACKLIGHT"
          fi
        fi
      '';
    };
  };
}
