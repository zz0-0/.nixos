{
  config,
  lib,
  pkgs,
  ...
}:

{
  # System-level environment variables for NVIDIA GPU offload
  environment.variables = {
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.intel-gpu-tools.enable = true;

  hardware.nvidia = {
    # RTX 5060 (Blackwell) requires open kernel modules
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    nvidiaSettings = true;
    modesetting.enable = true;
    prime = {
      # Offload mode - NVIDIA GPU only used when explicitly requested, saves battery
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:2:0:0";
    };
    # NVIDIA driver-level power management (runtime PM, D3cold)
    powerManagement.enable = true;
    powerManagement.finegrained = true;
  };

  # Fix screen capture/mirror dark screen on NVIDIA PRIME laptops
  # The wlr screencast portal needs WLR_RENDERER=wlr to capture properly
  # This forces the compositor to render via Intel so scanout works
  environment.sessionVariables = {
    WLR_RENDERER = "wlr";
  };
}
