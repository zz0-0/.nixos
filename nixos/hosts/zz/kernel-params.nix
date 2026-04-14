{ config, lib, ... }:

{
  # Legacy NVIDIA driver (580) needs ASPM disabled to avoid crashes
  boot.kernelParams = [ "pcie_aspm=off" ];
}
