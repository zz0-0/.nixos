{
  config,
  lib,
  pkgs,
  ...
}:

{
  boot = {
    initrd.systemd.enable = true;
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "nvidia_drm.modeset=1"
      "intel_iommu=on"
      "iommu=pt"
    ];
  };
}
