{
  config,
  pkgs,
  creamlinux,
  ...
}:

{
  # Packages here are part of the Home Manager generation, so changing this
  # list still requires a `nixos-rebuild switch` (HM is embedded in NixOS).
  # For occasional or experimental GUI apps, prefer:
  #   nix run nixpkgs#some-app
  #   nix profile install nixpkgs#some-app
  # and keep this list for things you want present on every login.
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
    pciutils

    # Image, Video & Audio Applications
    bluez
    kdePackages.kamoso
    kdePackages.kdenlive
    obs-studio
    aegisub
    gimp
    inkscape
    meshlab
    mpv
    python314Packages.hyperframe

    # Media & Document Applications
    celluloid
    libreoffice-stable

    # 3D
    blender

    # Download Managers
    gopeed

    # Gaming
    heroic
    creamlinux

    # Wayland & DMS Utilities
    cliphist
    dux-search
    playerctl
    wl-clip-persist
    wl-clipboard
    i2c-tools
    matugen

    # Audio clients (pactl is expected by Steam and some games)
    pulseaudio

    # AI
    opencode
  ];
}
