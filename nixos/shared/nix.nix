{
  config,
  lib,
  pkgs,
  ...
}:

{
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      builders-use-substitutes = true;
      always-allow-substitutes = true;
      max-jobs = "auto";
      cores = 0;
      # Disable sandbox to allow DNS resolution for builds using local DNS (AdGuardHome)
      sandbox = false;
      extra-sandbox-paths = [ "/etc/resolv.conf" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
