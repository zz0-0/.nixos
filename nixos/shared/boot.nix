{
  config,
  lib,
  pkgs,
  ...
}:

{
  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      systemd-boot.editor = false;
      efi.canTouchEfiVariables = true;
      # The default is 5 seconds. Two seconds still leaves time to pick an
      # older generation, without adding 5s to every boot.
      timeout = 2;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    # nvidia-drm.modeset=1 is added automatically by hardware.nvidia.modesetting.enable
  };
}
