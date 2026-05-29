{
  # Legacy NVIDIA driver (580) needs ASPM disabled to avoid crashes.
  # NVreg_DynamicPowerManagement=0x02: aggressively power down GPU when idle
  boot.kernelParams = [
    "pcie_aspm=off"
    "nvidia.NVreg_DynamicPowerManagement=0x02"
  ];
}
