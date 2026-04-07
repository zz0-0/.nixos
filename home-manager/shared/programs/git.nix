{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "zz0-0"; # replace with your username
      user.email = "zz11009988@outlook.com"; # replace with your email
    };
  };
  programs.gh = {
    enable = true;
  };
}
