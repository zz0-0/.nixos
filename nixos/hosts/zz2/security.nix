{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Fingerprint authentication (zz2 has a fingerprint reader, zz does not)
  services.fprintd.enable = true;

  # U2F / FIDO2 security key authentication
  security.pam.u2f = {
    enable = true;
    settings = {
      cue = true;
    };
  };
}
