{
  config,
  lib,
  pkgs,
  ...
}:

let
  nvidiaPackages = config.boot.kernelPackages.nvidiaPackages.latest;

  # NVIDIA 615 runs probe in an nv-probe kthread. On Linux 7.3, kthreads
  # start with an empty nullfs root, so the driver's filp_open() on
  # /sys/bus/pci/devices/<id>/config fails and it disables runtime D3
  # ("Runtime D3 status: Not supported"). This is the CachyOS fix that
  # wraps the lookup in scoped_with_init_fs(); it makes RTD3 report
  # "Enabled (fine-grained)" again on 7.3. Remove once NVIDIA ships it.
  nvidiaPatched = nvidiaPackages // {
    open = nvidiaPackages.open.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ../patches/nvidia-rtd3-7.3.patch ];
    });
  };
in
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
    package = nvidiaPatched;
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
