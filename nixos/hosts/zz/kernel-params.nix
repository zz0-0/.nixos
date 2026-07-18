{
  # ── Power Management ──────────────────────────────────────────────────
  #
  # pcie_aspm=force: enable PCIe ASPM even if BIOS claims it's unsupported.
  # Saves 5-10W by letting NVMe, WiFi, Thunderbolt enter low-power link states.
  # Standard recommendation from Arch Wiki / NixOS community for laptops.
  #
  # If NVIDIA GPU crashes/hangs after this change, try removing
  # NVreg_EnableGpuFirmware=0 first (GSP firmware is known to cause issues
  # on some laptops). If still broken, revert to pcie_aspm=off.
  #
  # NVreg_DynamicPowerManagement=0x00: NEVER power down the NVIDIA GPU.
  # Keeps HDMI port alive on battery (HDMI is wired through the dGPU).
  # Trade-off: ~2-5W extra battery drain when GPU would otherwise be idle.
  boot.kernelParams = [
    "pcie_aspm=force"
    "nvidia.NVreg_DynamicPowerManagement=0x00"
  ];
}
