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

  boot.kernelModules = [
    # WiFi
    "iwlwifi"
    "iwlmvm"
    "btintel"
    # I2C controllers (needed for the Goodix touchpad via i2c_hid_acpi + hid-multitouch)
    "i2c-designware-pci"
    "i2c-designware-core"
  ];

  # Blacklist btintel_pcie — it hangs for ~2 min probing device 0000:00:14.7
  # (Intel Bluetooth 8086:E376) with error -62 (hardware timeout), then gets
  # killed by systemd-udevd. The device doesn't work with this driver anyway.
  boot.blacklistedKernelModules = [ "btintel_pcie" ];

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
  #   libinput list-devices
  #   cat /proc/bus/input/devices | grep -A5 'Touchpad\|elan\|synaptics\|goodix'
  #   evtest /dev/input/event13  # test touchpad events directly
  #
  # For WiFi specifically, check if firmware loads:
  #   dmesg | grep iwlwifi
  # If you see "firmware: failed to load iwlwifi-gl-b0-fm-b0-XX.ucode",
  # we may need to manually add the firmware file.

  # Debug tools for touchpad/input issues
  environment.systemPackages = with pkgs; [
    libinput
    evtest
  ];
}
