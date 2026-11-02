{
  config,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    acme-sh
  ];

  sops.secrets."acme-sh/aliyun.env" = {
    sopsFile = ../../secrets/acme-sh/aliyun.env;
    format = "dotenv";
    owner = "root";
    mode = "0400";
  };

  systemd.services.acme-sh = {
    description = "Renew acme.sh certificates and deploy to Aliyun CDN";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    path = with pkgs; [
      acme-sh
      curl
      openssl
      coreutils
    ];

    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "acme-sh";
      StateDirectoryMode = "0700";
      EnvironmentFile = config.sops.secrets."acme-sh/aliyun.env".path;
      ExecStart = "${pkgs.acme-sh}/bin/acme.sh --cron --home /var/lib/acme-sh";
    };
  };

  systemd.timers.acme-sh = {
    description = "Daily acme.sh certificate renewal";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
