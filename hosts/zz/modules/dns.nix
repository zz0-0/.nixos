{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.resolved.enable = false;

  networking.nameservers = [ "127.0.0.1" ];

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
        bootstrap_dns = [
          "9.9.9.9"
          "149.112.112.112"
        ];
        upstream_dns = [
          "https://dns.quad9.net/dns-query"
        ];
      };
    };
  };
}
