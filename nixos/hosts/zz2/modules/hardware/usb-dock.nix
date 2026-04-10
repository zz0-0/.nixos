{
  config,
  lib,
  pkgs,
  ...
}:

{
  # HP Thunderbolt Dock G2 support
  # Works in USB-C mode (like on zz) — no Thunderbolt bolt service needed.
  # The dock falls back to standard USB-C + DisplayPort alt mode, which
  # works reliably on this hardware (Thunderbolt USB tunnel is broken on
  # newer Intel platforms).

  # Disable USB autosuspend for dock-connected devices
  # This prevents the dock from powering down USB ports for mouse/keyboard
  boot.kernelParams = [
    "usbcore.autosuspend=-1"
  ];

  # udev rules to disable power management for USB devices
  services.udev.extraRules = ''
    # Disable USB autosuspend for all USB devices (dock mouse/keyboard)
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"

    # Force power=on for USB hubs (catches dock's internal USB hub)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="09", ATTR{power/control}="on"

    # USB HID devices (mouse/keyboard) - never suspend
    ACTION=="add", SUBSYSTEM=="hid", DRIVERS=="usbhid", ATTR{power/control}="on"
  '';

  # USB HID polling optimization (reduces mouse lag)
  boot.extraModprobeConfig = ''
    options usbhid mousepoll=0
  '';
}
