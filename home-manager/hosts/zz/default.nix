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
    ../../shared/xdg.nix
    ../../shared/packages.nix
    ../../shared/portals.nix
    ../../shared/programs/dms.nix
    ../../shared/programs/editor.nix
    ../../shared/programs/git.nix
    ../../shared/programs/niri.nix
    ../../shared/services.nix
    ../../shared/shell.nix
    ../../shared/theme.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = systemVersion;
  };
}
