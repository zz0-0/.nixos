{ ... }:

{
  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
      };
      dns = "none";
    };
    # NetworkManager turns this on by default and it probes for WWAN modems
    # that this machine does not have. No modem, no daemon.
    modemmanager.enable = false;
    firewall = {
      enable = true;
    };
  };
}
