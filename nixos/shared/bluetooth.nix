{ config, lib, ... }:

{
  # Load btusb for USB Bluetooth adapters (built-in PCIe btintel_pcie is broken)
  boot.kernelModules = [
    "bluetooth"
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings = {
      General = {
        Experimental = true;
        AutoEnable = false;
      };
    };
  };
}
