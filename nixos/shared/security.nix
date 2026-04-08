{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # Fingerprint authentication
  services.fprintd = {
    enable = true;
    # Use tod for Goodix fingerprint sensors (common on modern laptops)
    # tod = enable;  # Goodix sensors use the "tod" (Touch On Demand) driver
  };

  # GNOME Keyring - auto-unlock on login
  services.gnome.gnome-keyring.enable = true;
  # Enable keyring auto-unlock for all relevant PAM services
  # This ensures the keyring is unlocked regardless of how you authenticate
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.systemd-user.enableGnomeKeyring = true;
  security.pam.services.dms-greeter.enableGnomeKeyring = true;
  security.pam.services.sudo.enableGnomeKeyring = true;

  # U2F / FIDO2 security key authentication
  security.pam.u2f = {
    enable = true;
    # Allow authentication with either fingerprint OR U2F key OR password
    # "cue" prompts the user to touch the security key
    # "nousertouch" skips the touch prompt for DMS which handles its own prompts
    settings = {
      cue = true;
      # authfile maps users to their U2F keys
      # Generated with: pamu2fcfg > ~/.config/Yubico/u2f_keys
    };
  };
}
