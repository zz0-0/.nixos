{
  config,
  lib,
  pkgs,
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

  # Fingerprint authentication (zz2 only - zz has no fingerprint reader)
  services.fprintd = {
    enable = true;
  };

  # GNOME Keyring - auto-unlock on login (needed for Evolution email passwords)
  services.gnome.gnome-keyring.enable = true;

  # U2F / FIDO2 security key authentication
  security.pam.u2f = {
    enable = true;
    settings = {
      cue = true;
    };
  };
}
