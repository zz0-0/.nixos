{ config, lib, ... }:

{
  services = {
    printing.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
  };
}
