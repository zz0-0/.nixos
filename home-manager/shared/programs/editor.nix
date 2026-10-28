{ config, pkgs, ... }:

{
  # pgtk = pure GTK, native Wayland (no XWayland) and still works in a terminal.
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
  };

  programs.zed-editor = {
    enable = true;
  };
}
