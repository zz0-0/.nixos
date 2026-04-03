{
  config,
  pkgs,
  niri,
  dankMaterialShell,
  username,
  systemVersion,
  ...
}:

{
  programs.home-manager.enable = true;

  imports = [
    niri.homeModules.niri
    dankMaterialShell.homeModules.dank-material-shell
    dankMaterialShell.homeModules.niri
    ./modules/xdg.nix
    ./modules/packages.nix
    ./modules/portals.nix
    ./modules/programs/dms.nix
    ./modules/programs/editor.nix
    ./modules/programs/git.nix
    ./modules/programs/niri.nix
    ./modules/services.nix
    ./modules/shell.nix
    ./modules/theme.nix

  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = systemVersion;
  };
}
