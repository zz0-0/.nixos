{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Thunderbolt/USB4 dock support
  # Ensures proper authorization and power management for dock-connected devices

  # Thunderbolt service - authorize connected devices
  services.hardware.bolt.enable = true;

  # Disable USB autosuspend for devices connected via dock
  # This prevents the dock from powering down USB ports for mouse/keyboard
  boot.kernelParams = [
    # Disable USB autosuspend globally (prevents dock USB ports from sleeping)
    "usbcore.autosuspend=-1"
  ];

  # udev rules to disable power management for USB controllers
  services.udev.extraRules = ''
    # Disable USB autosuspend for all USB devices
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"
  '';

  # Ensure USB4/Thunderbolt controllers are properly initialized
  # Load thunderbolt kernel module
  boot.kernelModules = [ "thunderbolt" ];

  # USB-related kernel modules (already in initrd, but ensure they're loaded early)
  boot.extraModprobeConfig = ''
    options usbhid mousepoll=0
  '';
}
