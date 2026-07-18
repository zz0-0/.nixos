{
  # ── Power Management ──────────────────────────────────────────────────
  #
  # pcie_aspm=off (for NVIDIA): RTX 5060 (Blackwell) has known issues
  # with ASPM — causes external display blanking. Driver 610.43.02 still
  # affected. ASPM for other devices (NVMe, WiFi) is enabled at runtime
  # via udev (see power.nix).
  #
  # NVreg_DynamicPowerManagement=0x03: fine-grained power control.
  # GPU enters D3cold + video memory powers off when idle (Ampere+).
  boot.kernelParams = [
    "pcie_aspm=off"
    "nvidia.NVreg_DynamicPowerManagement=0x03"
  ];
}
