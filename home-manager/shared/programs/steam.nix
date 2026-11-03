{ ... }:

{
  # Launch Steam itself under PRIME offload so every game it starts inherits
  # the NVIDIA environment. The normal Steam entry stays Intel for battery;
  # use this one when gaming. Per-game `prime-run` is then unnecessary.
  #
  # Written as a plain desktop file instead of xdg.desktopEntries: the current
  # Home Manager/DMS combination still passes the removed `extraConfig` option,
  # so the xdg.desktopEntries option is not usable here.
  home.file.".local/share/applications/steam-nvidia.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Steam (NVIDIA)
    Comment=Steam with PRIME offload to the NVIDIA GPU
    Exec=/run/current-system/sw/bin/prime-run /run/current-system/sw/bin/steam
    Icon=steam
    Terminal=false
    Categories=Game;
    StartupNotify=true
  '';
}
