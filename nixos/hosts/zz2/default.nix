{
  imports = [
    ./hardware-configuration.nix
    ../../shared/boot.nix
    ../../shared/dns.nix
    ../../shared/fonts.nix
    ../../shared/hardware.nix
    ./modules/hardware/bluetooth.nix
    ./modules/hardware/goodix-custom-driver.nix
    ./modules/hardware/gpu.nix
    ./modules/hardware/peripherals.nix
    ./modules/hardware/usb-dock.nix
    ../../shared/i18n.nix
    ./modules/network.nix
    ../../shared/nix.nix
    ../../shared/programs/steam.nix
    ../../shared/security.nix
    ../../shared/services.nix
    ./modules/storage.nix
    ../../shared/users.nix
  ];

  system.stateVersion = "26.05";
}
