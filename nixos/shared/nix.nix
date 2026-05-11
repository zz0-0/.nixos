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
      # Use OpenDNS/RootDNS for build DNS to avoid AdGuard blocking/crashing during builds
      build-users-group = "nixbld";
      trusted-substituters = [ "https://niri.cachix.org" ];
      trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
