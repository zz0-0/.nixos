{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking = {
    hostName = "zz"; # replace with your hostname
    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
      };
      dns = "none";
    };
    firewall = rec {
      enable = true;
      # allowedTCPPorts = [
      #   53
      #   3000
      # ];
      # allowedUDPPorts = [
      #   53
      # ];
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = allowedTCPPortRanges;

    };
  };

  systemd.services.wpa_supplicant.environment.OPENSSL_CONF = pkgs.writeText "openssl.cnf" ''
    openssl_conf = openssl_init
    [openssl_init]
    ssl_conf = ssl_sect
    [ssl_sect]
    system_default = system_default_sect
    [system_default_sect]
    Options = UnsafeLegacyRenegotiation
    CipherString = DEFAULT@SECLEVEL=1
  '';
}
