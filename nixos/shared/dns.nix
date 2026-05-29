{
  config,
  lib,
  pkgs,
  ...
}:

let
  fallbackDNS = [
    "8.8.8.8"
    "1.1.1.1"
    "9.9.9.9"
    "149.112.112.112"
  ];
in

{
  services.resolved.enable = false;

  # Disable resolvconf managing /etc/resolv.conf so we can write it directly.
  # openresolv has a bug where it only writes the first nameserver.
  networking.resolvconf.enable = false;

  # Write /etc/resolv.conf directly with both nameservers + a fallback.
  # 127.0.0.1 = AdGuardHome (for ad blocking)
  # 8.8.8.8    = fallback when AdGuard is down / unable to resolve
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
    nameserver 8.8.8.8
    options edns0
  '';

  services.adguardhome = {
    enable = true;
    host = "127.0.0.1";
    port = 3000;
    mutableSettings = false;
    openFirewall = false;
    settings = {
      dns = {
        bind_hosts = [ "127.0.0.1" ];
        port = 53;

        # Use only plain UDP upstreams.  DoH (https://dns.adguard-dns.com/dns-query)
        # requires bootstrapping via these addresses anyway, and may resolve to
        # IPv6 — which is broken on this network.  Plain DNS on IPv4 is simpler
        # and more reliable.
        bootstrap_dns = fallbackDNS;
        upstream_dns = fallbackDNS;
      };
    };
  };
}
