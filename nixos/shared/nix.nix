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
      # Make DNS resolution work inside sandbox when using local DNS (AdGuardHome)
      extra-sandbox-paths = [ "/etc/resolv.conf" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
