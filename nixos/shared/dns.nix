{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.resolved.enable = false;

  # Disable resolvconf managing /etc/resolv.conf so we can write it directly.
  # openresolv has a bug where it only writes the first nameserver.
  networking.resolvconf.enable = false;

  # /etc/resolv.conf: AdGuardHome on localhost is the primary resolver.
  # A second public resolver is kept only as a fallback for the case where
  # AdGuard is temporarily down; glibc tries 127.0.0.1 first and only falls
  # through after the timeout. Do not pin individual CDN IPs here — those
  # change and a stale entry breaks builds in a much more confusing way.
  #
  # timeout:3  → if no reply in 3 s, retry (was 1 s — too aggressive for builds)
  # attempts:3 → retry twice before giving up
  # edns0      → allow larger DNS packets (needed for DNSSEC, large filter lists)
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
    nameserver 1.1.1.1
    options edns0 timeout:3 attempts:3
  '';

  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    openFirewall = false;
    settings = {
      # Web UI / API listen address (replaces deprecated host/port options)
      http.address = "127.0.0.1:3000";
      schema_version = 34; # AdGuardHome 0.107.74

      dns = {
        bind_hosts = [ "127.0.0.1" ];
        port = 53;

        # ── Upstream DNS ───────────────────────────────────────────────
        # "parallel" fires queries to ALL upstreams at once and uses the
        # fastest response.  This gives you:
        #  - Chinese DNS for bilibili / domestic CDNs (nearby edge nodes)
        #  - Google / Cloudflare for everything else
        #
        # 223.5.5.5      = AliDNS (Alibaba)
        # 119.29.29.29    = DNSPod (Tencent)
        # 8.8.8.8         = Google
        # 1.1.1.1         = Cloudflare
        # 9.9.9.9         = Quad9 (malware filtering)
        upstream_mode = "parallel";
        upstream_dns = [
          "223.5.5.5"
          "119.29.29.29"
          "8.8.8.8"
          "1.1.1.1"
          "9.9.9.9"
        ];

        # Bootstrap DNS — used to resolve DoH/DoT names (we use plain UDP,
        # but the module assertion requires this to be set).
        bootstrap_dns = [
          "8.8.8.8"
          "1.1.1.1"
          "223.5.5.5"
        ];

        # ── Caching ────────────────────────────────────────────────────
        cache_size = 4194304; # 4 MB
        cache_ttl_min = 600; # Don't let TTLs drop below 10 min
        cache_ttl_max = 86400; # Cap TTLs at 24 h
        cache_optimistic = true; # Serve from cache while refreshing in background

        # ── EDNS Client Subnet ─────────────────────────────────────────
        # Sends a portion of your IP to upstreams so CDNs can route you to
        # the nearest edge node (important for video streaming).
        edns_client_subnet = {
          enabled = true;
          use_custom = false; # Use real client IP prefix
        };

        # ── Blocking ───────────────────────────────────────────────────
        # "default" = respond with 0.0.0.0 (connection refused instantly)
        blocking_mode = "default";
        blocking_ipv4 = "0.0.0.0";
        blocking_ipv6 = "::";

        # ── IPv6 ───────────────────────────────────────────────────────
        # IPv6 is broken on this network.  Drop ALL AAAA queries so
        # clients never try to connect over IPv6 — a common cause of
        # "hanging" when streaming from sites that publish AAAA records.
        aaa_disabled = true;

        # ── Security & rate-limiting ───────────────────────────────────
        enable_dnssec = true;
        ratelimit = 0; # Disabled — localhost builds need high QPS
      };

      filtering = {
        enabled = true;
        update_interval = 24; # Refresh filter lists every 24 hours

        filters = [
          # 1 — AdGuard DNS filter (baseline ad + tracker blocking)
          {
            enabled = true;
            url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
            name = "AdGuard DNS filter";
            id = 1700000000001;
          }

          # 2 — OISD Big (large, community-maintained, very low false-positive rate)
          {
            enabled = true;
            url = "https://big.oisd.nl/";
            name = "OISD Big";
            id = 1700000000002;
          }

          # 3 — HaGeZi Multi PRO (ads, tracking, malware, phishing — moderate aggression)
          {
            enabled = true;
            url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/multi.txt";
            name = "HaGeZi Multi PRO";
            id = 1700000000003;
          }
        ];
      };
    };
  };
}
