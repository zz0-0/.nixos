{ config, pkgs, ... }:

{
  # zz2 laptop - eDP-1: 3200x2000 @ 165Hz (BOE NS160MZ0-M00)
  programs.niri.settings.outputs = {
    "eDP-1" = {
      mode = {
        width = 3200;
        height = 2000;
        refresh = 165.0;
      };
      scale = 1.75;
      position = {
        x = 0;
        y = 0;
      };
    };
  };
}
