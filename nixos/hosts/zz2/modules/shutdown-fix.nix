{ config, lib, ... }:

{
  # Fix shutdown hang: systemd waits up to 90s for udev workers to settle
  # (often caused by NVIDIA GPU, USB dock, or btintel_pcie not releasing cleanly).
  # Reduce the timeout and ensure devices are properly powered down.
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
    DefaultTimeoutStartSec = "10s";
  };

  # udev rules: don't wait for USB/Thunderbolt/NVIDIA/Bluetooth devices during shutdown
  services.udev.extraRules = ''
    # Allow USB and Thunderbolt devices to disconnect during shutdown
    ACTION=="remove", SUBSYSTEM=="usb", GOTO="udev_end"
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}="1"
    ACTION=="remove", SUBSYSTEM=="thunderbolt", GOTO="udev_end"

    # Don't wait for NVIDIA GPU during shutdown
    SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TAG+="systemd", ENV{SYSTEMD_READY}="0"

    # Don't wait for btintel_pcie Bluetooth controller during shutdown
    SUBSYSTEM=="bluetooth", TAG+="systemd", ENV{SYSTEMD_READY}="0"

    # Mark all USB devices as not ready during shutdown to prevent udev hang
    ACTION=="remove", SUBSYSTEM=="usb", TAG+="systemd", ENV{SYSTEMD_READY}="0"
    LABEL="udev_end"
  '';
}
