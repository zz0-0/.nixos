{
  config,
  lib,
  pkgs,
  ...
}:

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

  # GNOME Keyring - auto-unlock on login
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.systemd-user.enableGnomeKeyring = true;
  security.pam.services.dms-greeter.enableGnomeKeyring = true;
  security.pam.services.sudo.enableGnomeKeyring = true;

  # greetd PAM: keyring auth must come AFTER pam_unix so the password is
  # available to unlock the login keyring. Default order has keyring (12200)
  # before unix (12900) — wrong. Override with raw text.
  security.pam.services.greetd.text =
    let
      gkr = "${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so";
    in
    ''
      # Auth: pam_unix collects password FIRST, then keyring uses it
      auth      sufficient  pam_u2f.so cue
      auth      sufficient  pam_fprintd.so
      auth      optional    pam_unix.so likeauth nullok
      auth      sufficient  pam_unix.so likeauth nullok try_first_pass
      auth      optional    ${gkr}
      auth      required    pam_deny.so
      # Account
      account   required    pam_unix.so
      # Password
      password  sufficient  pam_unix.so nullok yescrypt
      # Session: keyring auto_start uses password stored from auth phase
      session   required    pam_env.so conffile=/etc/pam/environment readenv=0
      session   required    pam_unix.so
      session   required    pam_loginuid.so
      session   optional    pam_systemd.so
      session   required    pam_limits.so
      session   optional    ${gkr} auto_start
    '';
}
