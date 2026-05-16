{ config, lib, pkgs, ... }:

{
  # Load btusb for USB Bluetooth adapters (built-in PCIe btintel_pcie is broken)
  boot.kernelModules = [
    "bluetooth"
  ];

  # hardware.pulseaudio = {
  #   enable = true;
  #   package = pkgs.pulseaudioFull;
  #   configFile = pkgs.writeText "default.pa" ''
  #     load-module module-switch-on-connect
  #     load-module module-bluetooth-policy
  #     load-module module-bluetooth-discover
  #     ## module fails to load with
  #     ##   module-bluez5-device.c: Failed to get device path from module arguments
  #     ##   module.c: Failed to load module "module-bluez5-device" (argument: ""): initialization failed.
  #     # load-module module-bluez5-device
  #     # load-module module-bluez5-discover
  #   '';
  # };

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
