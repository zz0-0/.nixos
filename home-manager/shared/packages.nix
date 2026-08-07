{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Theme $ Appearance
    adw-gtk3
    colloid-icon-theme
    phinger-cursors
    libsForQt5.qt5ct
    kdePackages.qt6ct

    # Browsers & Communication
    brave
    teams-for-linux
    wechat

    # File Managers & Utilities
    nautilus
    file-roller
    gnome-disk-utility
    evince

    # Ebook
    koodo-reader

    # Image, Video & Audio Applications
    bluez

    # Media & Document Applications
    celluloid
    libreoffice-fresh

    # Wayland & DMS Utilities
    cliphist
    dsearch
    wl-clipboard
    i2c-tools
    matugen

    # AI
    opencode
    rtk
  ];
}
