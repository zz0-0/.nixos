# Firmware updates

> 对应：`nixos/shared/firmware.nix`

`services.fwupd.enable` is on. fwupd refreshes LVFS metadata automatically via
`fwupd-refresh.timer`, but firmware/BIOS installation is intentionally manual:

```bash
sudo fwupdmgr get-devices
sudo fwupdmgr get-updates
sudo fwupdmgr update
```

