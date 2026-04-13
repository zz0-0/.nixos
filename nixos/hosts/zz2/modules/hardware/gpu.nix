{
  config,
  lib,
  pkgs,
  ...
}:

{
  # System-level environment variables for NVIDIA GPU offload
  # Games and applications can detect and use the NVIDIA GPU
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
    powerManagement.enable = true;
    powerManagement.finegrained = true;
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = "schedutil"; # power, performance, ondemand
  };

  hardware.system76.power-daemon.enable = true;
  services.system76-scheduler.enable = true;
}
