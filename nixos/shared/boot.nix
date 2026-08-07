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
      systemd-boot.editor = false;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    # nvidia-drm.modeset=1 is added automatically by hardware.nvidia.modesetting.enable
  };
}
