{
  # RTX 5060 (Blackwell) needs ASPM disabled to avoid boot hangs/crashes
  # USB params help with dock device enumeration
  boot.kernelParams = [
    "pcie_aspm=off"
    "usbcore.autosuspend=0"
    "usbcore.old_autosuspend=1"
    # Removed xhci.try_msi=0 (invalid param - doesn't exist in this kernel)
    # Removed duplicate nvidia-drm.modeset=1 entries
  ];
}
