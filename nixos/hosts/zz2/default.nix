{
  imports = [
    ./hardware-configuration.nix

    # Host-specific overrides
    ./hostname.nix
    ./modules/gpu.nix
    ./modules/storage.nix
    ./modules/peripherals.nix
    ./modules/goodix-custom-driver.nix
    ./security.nix

    # Shared modules
    ../../shared/boot.nix
    ../../shared/bluetooth.nix
    ../../shared/desktop.nix
    ../../shared/dns.nix
    ../../shared/fonts.nix
    ../../shared/firmware.nix
    ../../shared/i18n.nix
    ../../shared/network.nix
    ../../shared/nix.nix
    ../../shared/power.nix
    ../../shared/programs/steam.nix
    ../../shared/security.nix
    # ../../shared/shutdown.nix
    ../../shared/users.nix

    # Shared display/audio modules
    ../../shared/display/x11.nix
    ../../shared/display/dms.nix
    ../../shared/audio/pipewire.nix
  ];

  system.stateVersion = "26.05";
}
