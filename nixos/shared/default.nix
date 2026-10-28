{ ... }:

{
  imports = [
    ./audio/pipewire.nix
    ./bluetooth.nix
    ./boot.nix
    ./desktop.nix
    ./display/dms.nix
    ./display/x11.nix
    ./dns.nix
    ./fonts.nix
    ./firmware.nix
    ./i18n.nix
    ./network.nix
    ./nix.nix
    ./power.nix
    ./programs/evolution.nix
    ./programs/steam.nix
    ./security.nix
    ./users.nix
  ];
}
