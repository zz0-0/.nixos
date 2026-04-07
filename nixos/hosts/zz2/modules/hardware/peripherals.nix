{
  config,
  lib,
  pkgs,
  ...
}:

{
  # WiFi: Intel 8086:e340 (WiFi 7 BE202)
  # Uses iwlwifi driver - needs firmware
  # The firmware file needed is: iwlwifi-gl-b0-fm-b0-*.ucode

  # Ensure firmware is available
  hardware.enableRedistributableFirmware = true;

  # Touchpad: Goodix GXTP5100:00 27C6:01E7
  # Uses the goodix_i2c driver via hid-multitouch / i2c-hid subsystem
  boot.kernelModules = [
    # WiFi
    "iwlwifi"
    "iwlmvm"
    "btintel"
    # Touchpad - Goodix GXTP5100
    "i2c-hid"
    "i2c-hid-acpi"
    "hid-multitouch"
    "goodix"
    "i2c-designware-pci"
    "i2c-designware-core"
  ];

  boot.extraModprobeConfig = ''
    options iwlwifi power_save=1
  '';

  # Kernel params for Goodix touchpad / laptop hardware
  boot.kernelParams = [
    # Some Goodix touchpads need I2C controller reset at boot
    "i8042.nopnp"
  ];

  # If touchpad or WiFi still doesn't work, run these and share output:
  #   dmesg | grep -iE 'i2c|hid|touchpad|elan|synaptics|goodix'
  #   dmesg | grep -i 'iwlwifi\|8086:e340\|firmware'
  #   libinput list-devices
  #   cat /proc/bus/input/devices | grep -A5 'Touchpad\|elan\|synaptics\|goodix'
  #
  # For WiFi specifically, check if firmware loads:
  #   dmesg | grep iwlwifi
  # If you see "firmware: failed to load iwlwifi-gl-b0-fm-b0-XX.ucode",
  # we may need to manually add the firmware file.
}
