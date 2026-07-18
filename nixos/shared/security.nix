{ config, lib, ... }:

{
  # Polkit - auto-approve wheel group
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # GNOME Keyring - disabled to eliminate password prompts
  services.gnome.gnome-keyring.enable = false;
}
