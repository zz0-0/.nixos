{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Bluetooth enabled
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
