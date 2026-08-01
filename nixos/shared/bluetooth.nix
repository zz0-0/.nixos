{ config, pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;

    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };

      Policy.AutoEnable = false;
    };
  };

  systemd.user.services.mpris-proxy = {
    description = "MPRIS proxy";
    after = [ "network.target" "sound.target" ];
    wantedBy = [ "default.target" ];

    serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  };
}
