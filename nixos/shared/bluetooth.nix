_:

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

  # BlueZ already ships mpris-proxy.service. Only enable it here: adding an
  # ExecStart override creates a second ExecStart in the drop-in, which systemd
  # rejects ("Service has more than one ExecStart= setting").
  systemd.user.services.mpris-proxy.wantedBy = [ "default.target" ];
}
