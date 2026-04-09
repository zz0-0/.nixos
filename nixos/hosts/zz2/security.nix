{ config, lib, ... }:

{
  security.polkit.enable = true;

  # Fingerprint authentication (zz2 only - zz has no fingerprint reader)
  services.fprintd = {
    enable = true;
  };

  # GNOME Keyring - auto-unlock on login (needed for Evolution email passwords)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.systemd-user.enableGnomeKeyring = true;
  security.pam.services.dms-greeter.enableGnomeKeyring = true;
  security.pam.services.sudo.enableGnomeKeyring = true;

  # U2F / FIDO2 security key authentication
  security.pam.u2f = {
    enable = true;
    settings = {
      cue = true;
    };
  };

  # Fix: lock screen keeps polling fingerprint scanner repeatedly.
  # Disable fingerprint for the lock screen PAM service so it only accepts password.
  security.pam.services.swaylock.fprintAuth = false;
}
