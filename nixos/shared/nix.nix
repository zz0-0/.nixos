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
      accept-flake-config = true;
      auto-optimise-store = true;
      builders-use-substitutes = true;
      always-allow-substitutes = true;
      max-jobs = "auto";
      cores = 0;
      # Disable sandbox to allow DNS resolution for builds using local DNS (AdGuardHome)
      sandbox = false;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
