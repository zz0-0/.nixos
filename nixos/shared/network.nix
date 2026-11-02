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
    firewall = {
      enable = true;
    };
  };
}
