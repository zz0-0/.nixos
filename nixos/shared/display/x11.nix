{
  config,
  lib,
  pkgs,
  ...
}:

{
  services = {
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
  };
}
