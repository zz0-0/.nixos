{
  config,
  pkgs,
  niri,
  dankMaterialShell,
  username,
  systemVersion,
  system,
  ...
}:

let
  niriPkg = niri.packages.${system}.niri-unstable.overrideAttrs (_: {
    doCheck = false;
  });
in
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
    ./niri-outputs.nix
    ../../shared/services.nix
    ../../shared/shell.nix
    ../../shared/theme.nix
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
