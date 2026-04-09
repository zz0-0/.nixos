{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Thunderbolt/USB4 dock support (HP Thunderbolt Dock G2)
  # Ensures proper authorization and power management for dock-connected devices

  # Thunderbolt service - authorize connected devices
  services.hardware.bolt.enable = true;

  # Kernel parameters for dock stability
  boot.kernelParams = [
    # Disable USB autosuspend globally (prevents dock USB ports from sleeping)
    "usbcore.autosuspend=-1"
    # Disable USB power savings on the xhci controller (helps dock USB tunnel)
    "usbcore.old_scheme_first=1"
    # Disable PCIe ASPM power saving that can interfere with Thunderbolt
    "pcie_aspm=off"
  ];

  # udev rules for USB dock power management
  services.udev.extraRules = ''
    # Disable USB autosuspend for all USB devices (dock mouse/keyboard)
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"

    # Force power=on for USB hubs (catches dock's internal USB hub)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="09", ATTR{power/control}="on"

    # USB HID devices (mouse/keyboard) - never suspend
    ACTION=="add", SUBSYSTEM=="hid", DRIVERS=="usbhid", ATTR{power/control}="on"
  '';

  # Ensure USB4/Thunderbolt controllers are properly initialized
  boot.kernelModules = [ "thunderbolt" ];

  # USB HID polling optimization (reduces mouse lag)
  boot.extraModprobeConfig = ''
    options usbhid mousepoll=0
  '';

  # ============================================================
  # FALLBACK: If Thunderbolt USB tunnel fails (dock mouse/keyboard
  # don't work), connect a USB-A cable from the dock's upstream
  # USB-A port to the laptop's USB-A port.
  #
  # The autosuspend/power rules above will also apply to this
  # fallback connection, keeping mouse/keyboard responsive.
  # ============================================================
}
