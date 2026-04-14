{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  services = {
    displayManager = {
      dms-greeter = {
        enable = true;
        compositor.name = "niri";
        configHome = "/home/${username}";
      };
    };
  };
}
