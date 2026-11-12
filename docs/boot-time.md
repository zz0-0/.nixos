# Boot time

> 对应：`nixos/shared/boot.nix`、`nixos/hosts/zz2/modules/boot-tuning.nix`

`boot.loader.timeout = 2` is set in `nixos/shared/boot.nix`. The old default
was 5 seconds, which was the largest single chunk of boot time. zz2 breakdown
before the modules-load change:

```
firmware 5.43s + loader 2.30s + kernel 2.88s + initrd 2.69s + userspace 6.18s = 19.49s
```

and after it (also after the 7.3.4 update and the zstd initrd):

```
firmware 6.12s + loader 2.30s + kernel 0.79s + initrd 2.65s + userspace 5.33s = 17.19s
```

## Where the userspace seconds go

`systemd-analyze critical-chain` used to show a serial path, not a fan-out:

```
systemd-modules-load 1.97s → firewall 1.54s → NetworkManager 1.24s
→ adguardhome 0.04s → multi-user → graphical
```

`systemd-modules-load` used to be the first link because `nvidia_uvm` is loaded
there for the NVIDIA open module and its init takes ~3 s.
`nixos/hosts/zz2/modules/boot-tuning.nix` keeps the module out of
`modules-load.d` and loads it from a service after `multi-user.target`; the
details and the removal condition are in [docs/workarounds.md](workarounds.md).
After the change `systemd-modules-load` no longer shows up in `blame` at all —
the top entries are just device enumeration — and `/dev/nvidia-uvm` exists by
the time anything interactive runs.

The stock WiFi/Bluetooth modules are left to udev autoload instead of
`boot.kernelModules`, so `iwlmvm`'s firmware load no longer blocks
`systemd-modules-load`. The custom `btintel_pcie_fixed` and `goodix-gt7868q`
modules remain explicit because they are not autoloaded.

## initrd

`boot.initrd.compressor = "zstd"`: the ESP read is sequential and cheap, the
decompression is on the critical path, and zstd decompresses several times
faster than xz for a modestly larger file.

The initrd is systemd-based because that is now the only initrd nixpkgs has —
the scripted one was removed, so there is no option to set. `nixos-rebuild`
will reject `boot.initrd.systemd.enable` with "no longer has any effect".

What is left in that stage is the 15 MB Intel microcode blob plus systemd
userspace. Trimming `boot.initrd.availableKernelModules` was considered and
skipped: it needs `mkForce` on a generated list, saves a few tens of
milliseconds, and risks dropping a module a future kernel genuinely needs at
stage 1.

## systemd-boot's LoaderConfigTimeout

systemd-boot can store an explicit menu timeout in the `LoaderConfigTimeout`
EFI variable, and that NVRAM value overrides `loader.conf`. It survives
rebuilds and firmware updates, so the menu can silently go back to a longer
timeout even though `boot.nix` says 2. `nixos/shared/boot.nix` clears the
variable as part of bootloader installation, making the declarative value
authoritative. To inspect it manually:

```bash
od -An -tx1 -v /sys/firmware/efi/efivars/LoaderConfigTimeout-*
```

The remaining 5 s of firmware time is BIOS POST. Only the firmware setup can
shorten that, by disabling devices the machine does not boot from.
