{
  ...
}:

let
  gib = 1024 * 1024 * 1024;
in

{
  # ── CPU scheduler: sched_ext ───────────────────────────────────────────────
  # scx_lavd is the hybrid-aware scheduler from Valve: latency-sensitive work
  # stays on P-cores, background work is packed onto E-cores, and it reaches
  # the same throughput with fewer wakeups than EEVDF. That is the right shape
  # for a 16-thread Core Ultra laptop that both compiles and games.
  #
  # scx_loader keeps the kernel scheduler one command away, so this is not a
  # one-way change and does not need a rebuild to undo:
  #
  #   scxctl switch -s scx_bpfland   # try another scheduler
  #   scxctl stop                    # back to EEVDF for this boot
  #
  # Requires kernel 6.12+; services.scx-loader asserts that itself.
  services.scx-loader = {
    enable = true;
    config.default_sched = "scx_lavd";
  };

  # ── Compressed swap in RAM ─────────────────────────────────────────────────
  # The disk swap partition stays as the last resort. Normal memory pressure
  # should hit zram instead: a page there costs microseconds instead of an
  # NVMe round trip, and it is cheaper for battery than waking the disk.
  # Priority 100 beats the partition's -1, so the kernel fills zram first.
  #
  # 50 % of RAM is the device size, not the RAM it may consume: zstd data
  # lives in RAM at roughly a third of its original size.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
  };

  boot.kernelModules = [
    # Load what the sysctls below need, so they do not fail silently at boot.
    "tcp_bbr"
    "sch_fq"
  ];

  boot.kernelParams = [
    # This kernel is built PREEMPT_DYNAMIC with lazy preemption as the default
    # (CONFIG_PREEMPT_LAZY=y). Lazy favours throughput; `full` bounds how long
    # a runnable task may wait, which is what input latency and frame pacing
    # actually notice. Costs a little context-switch throughput.
    "preempt=full"

    # Collapse anonymous memory into 2 MB pages without waiting for madvise.
    # Worth it for compilers and games; costs some memory on workloads that
    # touch only part of each huge page.
    "transparent_hugepage=always"
  ];

  boot.kernel.sysctl = {
    # Swap anonymous pages into zram rather than evicting page cache. The
    # compressed page comes back cheaply; the dropped cache does not.
    "vm.swappiness" = 150;
    # zram decompresses in one go. The default 8-page readahead cluster only
    # wastes work and cache on a compressed device.
    "vm.page-cluster" = 0;

    # The default (20 % of 30 GB) lets 6 GB of dirty pages pile up, which
    # turns a big write — a kernel build, a Steam download — into multi-second
    # stalls for every other process. Bound it and start writeback early.
    "vm.dirty_bytes" = 2 * gib;
    "vm.dirty_background_bytes" = 512 * 1024 * 1024;

    # Games and JITs reserve address space they never fully touch; with the
    # default heuristic a large reservation can fail even when RAM is free.
    "vm.overcommit_memory" = 1;

    # BBR keeps throughput on the lossy, high-RTT links this machine sees;
    # fq is the qdisc BBR is designed against. Both are kernel modules, which
    # is why they are loaded above.
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # Default socket buffers cap a single stream at a few MB regardless of
    # link speed; 16 MB lets one download use the whole pipe.
    "net.core.rmem_max" = 16 * 1024 * 1024;
    "net.core.wmem_max" = 16 * 1024 * 1024;

    # Client and server side TFO: halves the handshake on repeated connections,
    # which is most of what a browser and the substituters do.
    "net.ipv4.tcp_fastopen" = 3;
  };

  # Mesa's shader cache is capped at 1 GB by default. DXVK and Vulkan titles
  # regenerate shaders when the cache evicts, which shows up as first-run and
  # after-patch stutter. 4 GB is ~nothing next to a 30 GB machine.
  environment.sessionVariables.MESA_SHADER_CACHE_MAX_SIZE = "4G";

  # zram is swap the kernel will fill long before it is out of memory, so the
  # 90 % swap threshold systemd-oomd kills at would fire while there is still
  # reclaimable RAM. The NixOS option only exposes the [OOM] section, so this
  # goes in as an oomd.conf drop-in. Memory-pressure heuristics stay untouched.
  environment.etc."systemd/oomd.conf.d/50-swap.conf".text = ''
    [Swap]
    UsedLimit=95%
  '';

  # relatime still writes the atime once a day per file that is read; noatime
  # removes those writes. Nothing here (mutt, tmpwatch) reads atime, and on a
  # laptop the difference is one less reason to wake the disk.
  fileSystems."/".options = [ "noatime" ];
}
