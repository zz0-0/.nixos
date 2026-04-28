{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.resolved.enable = false;

  networking.nameservers = [
    "127.0.0.1"
    "8.8.8.8"
  ];

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
          "https://dns.adguard-dns.com/dns-query"
          "94.140.14.14"
          "94.140.15.15"
        ];
      };
    };
  };
}
