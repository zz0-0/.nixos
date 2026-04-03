{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "zz0-0";
      user.email = "zz11009988@outlook.com";
    };
  };
  programs.gh = {
    enable = true;
  };
}
