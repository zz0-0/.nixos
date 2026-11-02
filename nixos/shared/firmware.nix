{ ... }:

{
  hardware.enableRedistributableFirmware = true;

  # fwupd refreshes LVFS metadata on a timer (fwupd-refresh.timer), but
  # firmware installation stays manual: `fwupdmgr get-updates` and then
  # `fwupdmgr update`. Do not auto-install BIOS/firmware updates.
  services.fwupd.enable = true;
}
