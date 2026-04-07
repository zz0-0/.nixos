{
  config,
  lib,
  pkgs,
  ...
}:

{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];
    fontDir.enable = true;
    enableDefaultPackages = false;
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        monospace = [ "Noto Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
      cache32Bit = true;
    };
  };
}
