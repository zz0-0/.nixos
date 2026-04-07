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
    # RTX 5060 - use latest driver (not legacy)
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    nvidiaSettings = true;
    modesetting.enable = true;
    prime = {
      offload.enable = true;
      # NOTE: Update these Bus IDs after running nixos-generate-config on zz2
      # Use `lspci | grep -E "VGA|3D"` to find the correct Bus IDs
      intelBusId = "PCI:0:2:0"; # Update this for zz2
      nvidiaBusId = "PCI:1:0:0"; # Update this for zz2
    };
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };
}
