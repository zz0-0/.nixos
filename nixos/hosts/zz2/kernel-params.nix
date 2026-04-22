{
  # RTX 5060 (Blackwell) needs ASPM disabled to avoid boot hangs/crashes
  boot.kernelParams = [ "pcie_aspm=off" ];
}
