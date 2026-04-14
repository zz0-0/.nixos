{ config, lib, ... }:

{
  # Fix USB tunnel establishment: use firmware's Internal Connection Manager
  # instead of kernel's for better USB4/TB3 compatibility (dock connects at
  # 20Gbps but USB hub never appears — tunnel never established).
  boot.kernelParams = [
    "thunderbolt.start_icm=1"
    # Disable USB autosuspend so dock keyboard/mouse don't get powered off
    "usbcore.autosuspend=-1"
  ];

  # Keep all USB devices powered on (dock, keyboard, mouse, hub)
  services.udev.extraRules = ''
    # Disable autosuspend for all USB devices
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"

    # Force power=on for USB hubs (dock's internal hub)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="09", ATTR{power/control}="on"

    # USB HID devices (keyboard/mouse) — never suspend
    ACTION=="add", SUBSYSTEM=="hid", DRIVERS=="usbhid", ATTR{power/control}="on"
  '';
}
