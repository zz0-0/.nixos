{ config, lib, ... }:

{
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # GNOME Keyring - auto-unlock on login
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.systemd-user.enableGnomeKeyring = true;
  security.pam.services.dms-greeter.enableGnomeKeyring = true;
  security.pam.services.sudo.enableGnomeKeyring = true;
}
