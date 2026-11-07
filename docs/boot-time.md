# Boot time

> 对应：`nixos/shared/boot.nix`

`boot.loader.timeout = 2` is set in `nixos/shared/boot.nix`. The old default
was 5 seconds, which was the largest single chunk of boot time. For reference,
the zz2 boot breakdown before this change was:

```
firmware 5.43s + loader 6.36s + kernel 1.81s + initrd 2.70s + userspace 5.07s
```

systemd-boot can also store an explicit menu timeout in the `LoaderConfigTimeout`
EFI variable, and that NVRAM value overrides `loader.conf`. It survives
rebuilds and firmware updates, so the menu can silently go back to a longer
timeout even though this file says 2. `nixos/shared/boot.nix` clears the
variable as part of bootloader installation, making the declarative value
authoritative. To inspect it manually:

```bash
od -An -tx1 -v /sys/firmware/efi/efivars/LoaderConfigTimeout-*
```

The stock WiFi/Bluetooth modules are left to udev autoload instead of
`boot.kernelModules`, so `iwlmvm`'s firmware load no longer blocks
`systemd-modules-load`. The custom `btintel_pcie_fixed` and
`goodix-gt7868q` modules remain explicit because they are not autoloaded.

