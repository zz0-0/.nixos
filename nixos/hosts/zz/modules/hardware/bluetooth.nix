{
  config,
  lib,
  pkgs,
  ...
}:

{
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
