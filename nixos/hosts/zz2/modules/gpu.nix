{
  config,
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

    # VA-API decode on the Intel iGPU. Without `intel-media-driver` libva finds
    # no iHD driver on this machine and every video — YouTube, calls, streams —
    # silently decodes on the CPU, which is one of the few remaining ways to
    # burn 10 W on battery. Brave already ships with
    # `--enable-features=AcceleratedVideoDecodeLinuxGL` and pins its GPU
    # process to the Intel render node, so the driver is the only missing piece.
    #
    # `vpl-gpu-rt` is the oneVPL runtime for the same Xe media engine; OBS and
    # ffmpeg use it for hardware encode. Verify after switching — the render
    # node number flips between boots, so look it up by driver:
    #   XE=$(for n in /dev/dri/renderD*; do
    #          [ "$(basename "$(readlink -f "/sys/class/drm/$(basename "$n")/device/driver")")" = xe ] && echo "$n"
    #        done | head -1)
    #   LIBVA_DRIVER_NAME=iHD vainfo --display drm --device "$XE"
    #   → "Intel iHD driver", VAProfileVP9Profile0 / AV1Profile0 entrypoints
    # In Brave, chrome://gpu must say "Video Decode: Hardware accelerated".
    # `nvidia-vaapi-driver` stays (it is pulled in by hardware.nvidia); it is
    # only used when LIBVA_DRIVER_NAME=nvidia, so it does not interfere.
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
  };

  hardware.intel-gpu-tools.enable = true;

  # nixpkgs keys the NVIDIA user-space graphics stack (Vulkan ICD,
  # nvidia-smi, nvidia-settings) off `services.xserver.videoDrivers`.
  # Setting this does not start Xorg; niri still uses xwayland-satellite.
  services.xserver.videoDrivers = [ "nvidia" ];

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

  # ── Keep ordinary apps off the dGPU ────────────────────────────────────
  # Anything that touches the NVIDIA device wakes it, and an awake dGPU costs
  # ~3.3 W idle (measured; ~9 W right after wake) and takes ~90 s to fall back
  # asleep. Vulkan enumeration is the sneaky path: Zed renders through wgpu and
  # Brave enumerates Vulkan devices, so both can wake the dGPU without ever
  # rendering a frame on it.
  #
  # Pointing the session's Vulkan loader at the Intel ICD only removes that
  # path. `prime-run` puts the NVIDIA ICD back, so games and CUDA still work:
  #   prime-run steam      → both ICDs, offload vars set
  #   nvidia-smi           → still wakes the GPU on demand
  environment.sessionVariables = {
    VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
  };

  # ── GPU launcher wrappers ──────────────────────────────────────────────

  environment.systemPackages = [
    # prime-run: run any app on the NVIDIA dGPU
    (pkgs.writeScriptBin "prime-run" ''
      #!${pkgs.runtimeShell}
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      # Undo the Intel-only Vulkan pin from the session (see above).
      export VK_DRIVER_FILES="/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json:/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"
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
