{
  lib,
  config,
  pkgs,
  ...
}:

{
  programs.steam = {
    enable = true;
    fontPackages = with pkgs; [ noto-fonts-cjk-sans ];
  };
  programs.gamescope = {
    enable = true;
  };
  programs.gamemode = {
    enable = true;
  };
  programs.xwayland = {
    enable = true;
  };
}
