{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Theme $ Appearance
    yaru-theme
    colloid-icon-theme
    phinger-cursors
    libsForQt5.qt5ct
    kdePackages.qt6ct

    # Browsers & Communication
    brave
    teams-for-linux
    evolution
    evolution-ews
    wechat

    # File Managers & Utilities
    nautilus
    file-roller
    gnome-disk-utility
    evince

    # Download Manager
    gopeed

    # Gaming
    heroic

    # Ebook
    calibre

    # Remote Desktop
    remmina

    # Image, Video & Audio Applications
    snapshot
    bluez

    # Media & Document Applications
    celluloid

    # Wayland & DMS Utilities
    xwayland-satellite
    cliphist
    dsearch
    wl-clipboard
    wl-mirror
    i2c-tools
    matugen

    # AI Agents
    # claude-code
    opencode
    qwen-code
    codex
    github-copilot-cli
  ];

}
