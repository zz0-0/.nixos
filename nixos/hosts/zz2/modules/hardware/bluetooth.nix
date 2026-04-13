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
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        AutoEnable = false;
      };
    };
  };
}
