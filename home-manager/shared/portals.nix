{
  config,
  lib,
  pkgs,
  ...
}:

{
  xdg.portal = pkgs.lib.mkForce {
    enable = true;
    xdgOpenUsePortal = true;

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
