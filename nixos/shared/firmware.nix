{ lib, ... }:

{
  hardware.enableRedistributableFirmware = true;

  # fwupd stays available, but its LVFS metadata refresh is no longer a timer.
  # `fwupdmgr get-updates` refreshes on demand anyway, so the weekly fetch only
  # buys a background network round trip and a wakeup. Firmware installation
  # was already manual on purpose: `fwupdmgr get-updates` then `fwupdmgr update`.
  services.fwupd.enable = true;
  systemd.timers.fwupd-refresh.wantedBy = lib.mkForce [ ];
}
