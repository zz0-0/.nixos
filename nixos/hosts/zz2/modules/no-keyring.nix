{ config, lib, ... }:

{
  # Re-enable gnome-keyring (Evolution needs it for email passwords)
  services.gnome.gnome-keyring.enable = true;

  # The lock screen keeps prompting for fingerprint repeatedly.
  # Disable fingerprint for the lock screen's PAM service so it only
  # accepts password and stops polling the scanner.
  # DMS lock screen uses pam_swaylock as its PAM service name.
  security.pam.services.swaylock.fprintAuth = false;
}
