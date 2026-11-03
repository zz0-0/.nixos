{
  lib,
  niri,
  dankMaterialShell,
  username,
  systemVersion,
  niriPkg,
  ...
}:

{
  programs.home-manager.enable = true;

  # Keep this: the NixOS GC collects old system generations, but old
  # home-manager generations are user-profile roots. Without this timer they
  # stay pinned in the store even after the system GC runs.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # PAM starts gnome-keyring at login (NixOS sets
  # security.pam.services.*.enableGnomeKeyring). niri's Home Manager module
  # also enables the HM user unit, which starts a second daemon and logs
  # "already initialized". The PAM instance owns the secrets service, so keep
  # only that one.
  services.gnome-keyring.enable = lib.mkForce false;

  # Portals are configured at the NixOS level (see flake.nix). niri's HM module
  # also enables the HM portal instance, which duplicates D-Bus service files
  # in the user profile. Keep only the system instance.
  xdg.portal.enable = lib.mkForce false;

  imports = [
    niri.homeModules.niri
    dankMaterialShell.homeModules.dank-material-shell
    dankMaterialShell.homeModules.niri
    ./packages.nix
    ./programs/dsh.nix
    ./programs/dms.nix
    ./programs/editor.nix
    ./programs/evolution.nix
    ./programs/git.nix
    ./programs/pbz.nix
    ./programs/steam.nix
    ./programs/teams.nix
    ./shell.nix
    ./theme.nix
    {
      programs.niri.package = niriPkg;
    }
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = systemVersion;
  };
}
