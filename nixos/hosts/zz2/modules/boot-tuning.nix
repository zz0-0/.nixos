{
  config,
  lib,
  pkgs,
  ...
}:

# Kernel-level choices that are host-local on purpose: they trade something
# away (security, boot-path simplicity) and only make sense after measuring
# this machine. Do not lift them into nixos/shared without that trade in mind.

{
  # ── CPU vulnerability mitigations ──────────────────────────────────────────
  # Turns off the speculative-execution mitigations (Spectre/Meltdown/Retbleed/
  # MDS/...). The win is real on syscall-heavy work — compilers, VMs, game
  # shader compilation through Proton. The cost is also real: code already
  # running on this machine can reach the side channels the mitigations close.
  # An attacker still needs local code execution first, which is not the usual
  # threat on a single-user laptop; that is the whole argument for this line.
  #
  # Verify what the kernel actually did: `journalctl -k | grep -i mitigation`
  # or `cat /sys/devices/system/cpu/vulnerabilities/*`. Removing this line is
  # the entire revert.
  boot.kernelParams = [ "mitigations=off" ];

  # ── nvidia_uvm off the boot path ───────────────────────────────────────────
  # nixpkgs adds nvidia_uvm to boot.kernelModules for the open module because
  # the `softdep nvidia post: nvidia-uvm` path does not work there. Loading it
  # in systemd-modules-load costs ~3s of the boot chain (it initialises UVM,
  # and modules-load sits in front of firewall → NetworkManager → multi-user),
  # which is a third of userspace boot.
  #
  # Removing one entry from a list option has no supported primitive, and
  # mkForce on boot.kernelModules would silently drop every default nixpkgs
  # adds later. So leave the list alone and rewrite the file systemd actually
  # reads. This keeps `config.boot.kernelModules` as the source of truth: the
  # filtered copy is derived from it, not hardcoded.
  #
  # The module is still loaded at boot, just after multi-user.target is up, so
  # CUDA has it by the time anything interactive starts. Details and the
  # removal condition: docs/workarounds.md.
  environment.etc."modules-load.d/nixos.conf" = lib.mkForce {
    text = lib.concatStringsSep "\n" (lib.remove "nvidia_uvm" config.boot.kernelModules);
  };

  systemd.services.nvidia-uvm-load = {
    description = "Load nvidia_uvm after boot instead of during it";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      # udev's own nvidia_uvm rule creates the device nodes once the module is
      # in, so a plain modprobe is enough here.
      ExecStart = "${pkgs.kmod}/bin/modprobe nvidia_uvm";
    };
  };
}
