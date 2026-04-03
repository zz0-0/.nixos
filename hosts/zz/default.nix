{
  inputs,
  lib,
  config,
  pkgs,
  oldPkgs,
  username,
  systemVersion,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/boot.nix
    ./modules/dns.nix
    ./modules/fonts.nix
    ./modules/hardware.nix
    ./modules/hardware/bluetooth.nix
    ./modules/hardware/gpu.nix
    ./modules/i18n.nix
    ./modules/network.nix
    ./modules/nix.nix
    ./modules/programs/steam.nix
    ./modules/security.nix
    ./modules/services.nix
    ./modules/storage.nix
    ./modules/users.nix
  ];

  system = {
    stateVersion = systemVersion;
  };
}
