{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.upower.enable = true;

  services.tlp = {
    enable = true;
    pd.enable = true;
  };
}
