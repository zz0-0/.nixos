{
  config,
  lib,
  pkgs,
  ...
}:

{
  # NOTE: Do NOT set __NV_PRIME_RENDER_OFFLOAD or __GLX_VENDOR_LIBRARY_NAME
  # globally — that forces EVERY app (compositor, terminal, browser) onto
  # the NVIDIA GPU, preventing it from ever reaching D3cold idle.
  #
  # Instead, use the prime-run wrapper below to launch only GPU-heavy apps:
  #   prime-run steam          → all Steam games use NVIDIA
  #   prime-run blender
  #   prime-run %command%      → in Steam launch options for a single game

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

  # ── GPU launcher wrappers ──────────────────────────────────────────────

  environment.systemPackages = [
    # prime-run: run any app on the NVIDIA dGPU
    (pkgs.writeScriptBin "prime-run" ''
      #!${pkgs.runtimeShell}
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')

    # wl-mirror: force Intel GPU to fix screen capture on PRIME laptops
    (pkgs.writeScriptBin "wl-mirror" ''
      #!${pkgs.runtimeShell}
      export NVIDIA_VISIBLE_DEVICES=void
      export __NV_PRIME_RENDER_OFFLOAD=0
      exec ${pkgs.wl-mirror}/bin/wl-mirror "$@"
    '')
  ];
}
