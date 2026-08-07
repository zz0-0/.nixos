{
  config,
  lib,
  pkgs,
  ...
}:

{
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    # xdg-desktop-portal-gnome is added by the niri home module for screencasting
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];

    config = {
      common = {
        default = [ "gtk" ];
      };
      niri = {
        default = [
          "gtk"
          "gnome"
        ];

        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
  };
}
