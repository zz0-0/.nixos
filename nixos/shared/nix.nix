{
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

      # Cap total parallelism instead of letting auto/0 spawn cores*cores
      # compile jobs on a 16-thread machine with 30 GB RAM.
      max-jobs = 4;
      cores = 4;
      build-users-group = "nixbld";

      # Keep the sandbox enabled (the default). If a specific derivation
      # genuinely needs network access, use __noChroot for that derivation
      # instead of weakening every build on the machine.
      #
      # auto-optimise-store is deliberately NOT enabled: it hashes every new
      # store path during builds. nix.optimise below runs the same operation
      # on a timer instead.

      # cache.nixos.org comes from the NixOS default; listing it here too
      # produces a duplicate entry in nix.conf.
      substituters = [
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
      openssl
      curl
      icu
      libxml2
      glib
      dbus
      fontconfig
      freetype
      libGL
      libx11
      libxext
      libxrender
      libxtst
      libxi
    ];
  };

  # Keep the system journal bounded instead of vacuuming it manually.
  services.journald.settings.Journal.SystemMaxUse = "500M";
}
