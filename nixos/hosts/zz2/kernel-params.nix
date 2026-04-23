{
  # RTX 5060 (Blackwell) needs ASPM disabled to avoid boot hangs/crashes
  # USB params help with dock device enumeration
  boot.kernelParams = [
    "pcie_aspm=off"
    "usbcore.autosuspend=0"
    "usbcore.old_autosuspend=1"
  ];
}
