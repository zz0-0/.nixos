{ ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Host-specific overrides
    ./hostname.nix
    ./modules/gpu.nix
    ./modules/peripherals.nix
    ./modules/goodix-custom-driver.nix
    ./modules/btintel-pcie-fix.nix
    ./security.nix

    # Shared NixOS baseline
    ../../shared
  ];

  # zz2 panel: 3200x2000, 165 Hz on AC / 60 Hz on battery.
  # Keeping these values host-local avoids applying zz2's panel settings to zz.
  laptop.display = {
    output = "eDP-1";
    backlight = "intel_backlight";
    brightnessAC = 496;
    brightnessBattery = 150;
    modeAC = "3200x2000@165.000";
    modeBattery = "3200x2000@60.001";
  };

  system.stateVersion = "26.05";
}
