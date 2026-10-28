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
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    nvidiaSettings = true;
    modesetting.enable = true;
    prime = {
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    powerManagement.enable = true;
    powerManagement.finegrained = true;
  };

  # zz's Intel GPU uses the i915 driver. On zz2 the GPU uses xe, where these
  # options are inert, so they live in the host-specific module rather than
  # in nixos/shared/power.nix.
  boot.extraModprobeConfig = ''
    options i915 enable_fbc=1 enable_psr=1 enable_guc=3
  '';
}
