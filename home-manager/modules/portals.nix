{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.sessionVariables = pkgs.lib.mkForce {
    XDG_DATA_DIRS = "/run/current-system/sw/share:${config.home.homeDirectory}/.nix-profile/share";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "niri";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_STYLE_OVERRIDE = "";
  };

  xdg.portal = pkgs.lib.mkForce {
    enable = true;
    xdgOpenUsePortal = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];

    config = {
      common = {
        default = [ "gtk" ];
      };
      niri = {
        default = [
          "gtk"
          "wlr"
        ];

        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
  };
}
