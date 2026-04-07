{ config, pkgs, ... }:

{
  # zz laptop - eDP-1: 1920x1080 @ 144Hz
  programs.niri.settings.outputs = {
    "eDP-1" = {
      mode = {
        width = 1920;
        height = 1080;
        refresh = 143.999;
      };
      position = {
        x = 0;
        y = 0;
      };
    };
  };
}
