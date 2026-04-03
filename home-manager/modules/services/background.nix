{ config, pkgs, ... }:

{
  services = {
    mpris-proxy.enable = true;
    kdeconnect.enable = true;
  };
}
