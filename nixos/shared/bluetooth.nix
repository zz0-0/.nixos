{ config, lib, pkgs, ... }:

{
  # Load btusb for USB Bluetooth adapters (built-in PCIe btintel_pcie is broken)
  boot.kernelModules = [
    "bluetooth"
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = false;
      };
    };
  };

  systemd.user.services.mpris-proxy = {
      description = "Mpris proxy";
      after = [ "network.target" "sound.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  };
}
