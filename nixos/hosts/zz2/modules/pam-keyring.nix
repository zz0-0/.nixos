{ config, lib, ... }:

{
  # Fix: gnome-keyring prompts for password even after fingerprint login
  # Because fingerprint auth doesn't provide a password, pam_gnome_keyring's
  # try_first_pass falls back to prompting.
  # Solution: write the full PAM config with 'use_first_pass' (fails silently
  # instead of prompting) in the session phase.
  security.pam.services.dms-greeter = {
    enableGnomeKeyring = lib.mkForce false;
    text = lib.mkForce ''
      auth      sufficient  pam_unix.so
      auth      sufficient  pam_fprintd.so
      auth      required    pam_deny.so

      password  required    pam_unix.so

      session   required    pam_unix.so
      session   optional    pam_gnome_keyring.so autostart use_first_pass
    '';
  };
}
