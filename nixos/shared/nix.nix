{
  config,
  lib,
  pkgs,
  ...
}:

{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      builders-use-substitutes = true;
      max-jobs = "auto";
      cores = 0;
      build-users-group = "nixbld";

      # Keep the sandbox enabled (the default). If a specific derivation
      # genuinely needs network access, use __noChroot for that derivation
      # instead of weakening every build on the machine.
      #
      # auto-optimise-store is deliberately NOT enabled: it hashes every new
      # store path during builds. nix.optimise below runs the same operation
      # on a timer instead.

      substituters = [
        "https://cache.nixos.org"
        "https://niri.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    optimise = {
      automatic = true;
      dates = "Sun 03:45";
    };

    gc = {
      automatic = true;
      dates = "Sun 04:30";
      options = "--delete-older-than 7d";
    };
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
    ];
  };

  # Keep the system journal bounded instead of vacuuming it manually.
  services.journald.settings.Journal.SystemMaxUse = "500M";
}
