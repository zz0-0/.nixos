{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  services = {
    printing.enable = true;
    libinput = {
      enable = true;
    };
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        options = "numpad:mac";
      };
      videoDrivers = [
        "nvidia"
        "intel"
      ];
      displayManager = {
        setupCommands = "${pkgs.numlockx}/bin/numlockx on ";
      };
    };
    displayManager = {
      dms-greeter = {
        enable = true;
        compositor.name = "niri";
        configHome = "/home/${username}";
      };
    };
    gvfs.enable = true;
    udisks2.enable = true;
    power-profiles-daemon.enable = true;
    upower.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
