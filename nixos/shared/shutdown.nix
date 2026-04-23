{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Fix shutdown hang: systemd waits up to 90s for udev workers to settle
  # (often caused by NVIDIA GPU, USB dock, or btintel_pcie not releasing cleanly).
  # Reduce the timeout to prevent long waits.
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
    DefaultTimeoutStartSec = "10s";
  };

  # udev rules: don't wait for USB/NVIDIA/Bluetooth devices during shutdown
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
  '';

  # HP Thunderbolt Dock G2 authorization at boot and resume
  systemd.services.hp-thunderbolt-dock = {
    description = "Authorize HP Thunderbolt Dock G2";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      # Wait for thunderbolt bus to settle, authorize dock, stay running
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo \"hp-dock: Starting, waiting 5s...\" > /dev/kmsg; sleep 5; echo 1 > /sys/bus/thunderbolt/devices/0-1/authorized 2>/dev/null || true; echo \"hp-dock: Authorized, reading: $(cat /sys/bus/thunderbolt/devices/0-1/authorized 2>/dev/null || echo \"fail\")\" > /dev/kmsg; sleep infinity'";
      # Re-authorize after resume with longer delay
      ExecStopPost = "${pkgs.bash}/bin/bash -c 'echo \"hp-dock: Stopping, waiting 3s...\" > /dev/kmsg; sleep 3; echo 1 > /sys/bus/thunderbolt/devices/0-1/authorized 2>/dev/null || true; echo \"hp-dock: Re-authorized\" > /dev/kmsg'";
    };
  };

  # Re-authorize HP Thunderbolt Dock G2 after resume from suspend
  systemd.services.systemd-suspend = {
    serviceConfig = {
      # Longer delay to allow Thunderbolt bus to fully re-settle after resume
      ExecStartPost = "${pkgs.bash}/bin/bash -c 'echo \"suspend: post-resume, waiting 5s...\" > /dev/kmsg; sleep 5; echo 1 > /sys/bus/thunderbolt/devices/0-1/authorized 2>/dev/null || true; echo \"suspend: Re-authorized\" > /dev/kmsg'";
    };
  };
}
