{
  config,
  pkgs,
  niri,
  dankMaterialShell,
  username,
  systemVersion,
  system,
  niriPkg,
  ...
}:

{
  programs.home-manager.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  imports = [
    niri.homeModules.niri
    dankMaterialShell.homeModules.dank-material-shell
    dankMaterialShell.homeModules.niri
    ./packages.nix
    ./programs/dms.nix
    ./programs/editor.nix
    ./programs/evolution.nix
    ./programs/git.nix
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
