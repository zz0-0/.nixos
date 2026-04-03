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
        FastConnectable = true;
        AutoEnable = false;
        Enable = "Source,Sink,Media,Socket";
      };
      Policy = {
        AutoEnable = false;
      };
    };
  };
}
