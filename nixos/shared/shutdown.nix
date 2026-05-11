{
  config,
  lib,
  pkgs,
  ...
}:

{
  # AGGRESSIVE SHUTDOWN: short timeouts, kill stuck services fast
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "5s"; # was 10s - only wait 5s before SIGKILL
    DefaultTimeoutStartSec = "5s";
    # Fail fast - don't retry failing services
    StartLimitIntervalSec = "1s";
    StartLimitBurst = "2";
  };

  # udev rules: keep USB devices powered and prevent autosuspend
  services.udev.extraRules = ''
    # Allow USB devices to disconnect during shutdown
    ACTION=="remove", SUBSYSTEM=="usb", GOTO="udev_end"

    # Don't wait for NVIDIA GPU during shutdown
    SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TAG+="systemd", ENV{SYSTEMD_READY}="0"

    # Don't wait for btintel_pcie Bluetooth controller during shutdown
    SUBSYSTEM=="bluetooth", TAG+="systemd", ENV{SYSTEMD_READY}="0"

    # Mark all USB devices as not ready during shutdown to prevent udev hang
    ACTION=="remove", SUBSYSTEM=="usb", TAG+="systemd", ENV{SYSTEMD_READY}="0"
    LABEL="udev_end"

    # Keep all USB devices powered (disable autosuspend)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{power/control}="on"
  '';

  # HP Thunderbolt Dock G2 authorization at boot and resume
  systemd.services.hp-thunderbolt-dock = {
    description = "Authorize HP Thunderbolt Dock G2";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo hp-dock > /dev/kmsg; sleep 2; echo 1 > /sys/bus/thunderbolt/devices/0-1/authorized 2>/dev/null || true; echo done > /dev/kmsg'";
      # Re-authorize on service stop (which happens on suspend)
      ExecStop = "${pkgs.bash}/bin/bash -c 'echo hp-dock-stop > /dev/kmsg; sleep 1; echo 1 > /sys/bus/thunderbolt/devices/0-1/authorized 2>/dev/null || true'";
    };
  };

  # Re-authorize HP Thunderbolt Dock G2 and power USB devices after resume from suspend
  systemd.services.systemd-suspend = {
    serviceConfig = {
      ExecStopPost = "${pkgs.bash}/bin/bash -c 'echo resume > /dev/kmsg; sleep 2; echo 1 > /sys/bus/thunderbolt/devices/0-1/authorized 2>/dev/null || true; for d in /sys/bus/usb/devices/3-4 /sys/bus/usb/devices/3-6; do echo on > $d/power/control 2>/dev/null || true; done; echo done > /dev/kmsg'";
    };
  };
}
