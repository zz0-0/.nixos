{
  config,
  lib,
  pkgs,
  ...
}:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    nvidiaSettings = true;
    modesetting.enable = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:2:0:0";
    };
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };
}
