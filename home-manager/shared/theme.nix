{
  pkgs,
  ...
}:

{
  gtk = {
    enable = true;
    colorScheme = "dark";
    gtk3.colorScheme = "dark";
    gtk4.colorScheme = "dark";
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    cursorTheme = {
      name = "phinger-cursors-light";
      package = pkgs.phinger-cursors;
      size = 24;
    };
    iconTheme = {
      name = "Colloid-Dark";
      package = pkgs.colloid-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "adw-gtk3-dark";
  };

  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "adw-gtk3-dark";
      # libadwaita ignores this legacy key and logs a warning; color-scheme
      # above is the supported way to request dark mode.
      color-scheme = "prefer-dark";
    };
  };

  home.sessionVariables = {
    GTK_USE_PORTAL = "1";
    GTK_THEME = "adw-gtk3-dark";
  };
}
