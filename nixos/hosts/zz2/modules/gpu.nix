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
  # Anything that touches the NVIDIA device wakes it, and an awake dGPU is not
  # cheap. Measured on battery at 0 % utilisation: 8.8 W with the GPU in
  # runtime D3 vs 22.0 W with it awake (nvidia-smi independently reports
  # 12.4 W for the card alone). It falls back asleep 20-90 s after the last
  # client closes. Vulkan enumeration is the sneaky path: Zed renders through
  # wgpu and Brave enumerates Vulkan devices, so both can wake the dGPU
  # without ever rendering a frame on it.
  #
  # Pointing the session's Vulkan loader at the Intel ICD only removes that
  # path. `prime-run` puts the NVIDIA ICD back, so games and CUDA still work:
  #   prime-run steam      → both ICDs, offload vars set
  #   nvidia-smi           → still wakes the GPU on demand
  environment.sessionVariables = {
    VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
  };

  # sessionVariables only reaches the systemd user manager once the compositor
  # runs `systemctl --user import-environment`. Units that start before that —
  # teams-for-linux does, 4 s after graphical-session-pre.target — miss it and
  # still enumerate the NVIDIA ICD (verified: VK_DRIVER_FILES absent from the
  # running teams process). environment.d is read when the user manager starts,
  # before any unit, so it covers those too.
  environment.etc."environment.d/10-vulkan-intel.conf".text = ''
    VK_DRIVER_FILES=/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json
  '';

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

  # ── Runtime D3 is decided once per boot ────────────────────────────────
  # The patched probe (nvidia-rtd3-7.3.patch) runs in an nv-probe kthread.
  # When its filp_open() loses the root-fs race the driver reports
  # "Runtime D3 status: Not supported" and disables RTD3 for the *whole
  # boot*: the dGPU then sits in D0 at 0 % utilisation drawing ~13 W.
  # Nothing in top, powertop or nvidia-smi shows it — the boot looks and
  # behaves completely normal at ~25 W on battery.
  #
  # So verify it once at boot, while nothing holds the module yet, and
  # re-probe when it came up wrong. The failure is per-probe, so a second
  # probe almost always wins. If all three lose, the unit fails loudly in
  # `systemctl --failed` instead of hiding 13 W for three hours.
  systemd.services.nvidia-rtd3-check = {
    description = "Verify NVIDIA runtime D3 is enabled, re-probe if not";
    wantedBy = [ "multi-user.target" ];
    # Must run before any compositor opens /dev/nvidia*.
    before = [ "greetd.service" ];
    after = [ "systemd-modules-load.service" ];
    path = [
      pkgs.kmod
      pkgs.gnugrep
      pkgs.coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      status_file="$(ls /proc/driver/nvidia/gpus/*/power 2>/dev/null | head -n1)"
      [ -n "$status_file" ] || exit 0

      for attempt in 1 2 3; do
        if grep -q 'Runtime D3 status:[[:space:]]*Enabled' "$status_file"; then
          echo "runtime D3 enabled (attempt $attempt)"
          exit 0
        fi
        grep 'Runtime D3 status' "$status_file" >&2 || true
        # greetd has not started yet, so nothing can hold the module.
        if ! modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia; then
          echo "cannot unload the nvidia modules, leaving them alone" >&2
          break
        fi
        modprobe nvidia_drm || break
        sleep 1
      done

      # Never leave the boot without nvidia-drm: prime-run needs it.
      modprobe nvidia_drm 2>/dev/null || true
      echo "runtime D3 still disabled: the dGPU will not sleep this boot" >&2
      echo "expect ~25 W on battery until the next reboot" >&2
      exit 1
    '';
  };
}
