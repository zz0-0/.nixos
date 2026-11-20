{ stateVersion, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Host-specific overrides
    ./hostname.nix
    ./modules/gpu.nix
    ./modules/boot-tuning.nix
    ./modules/hibernate.nix
    ./modules/intel-lpmd.nix
    ./modules/peripherals.nix
    ./modules/goodix-custom-driver.nix
    ./modules/btintel-pcie-fix.nix
    ./security.nix

    # Shared NixOS baseline
    ../../shared
  ];

  # zz2 panel: 3200x2000, 165 Hz on AC / 60 Hz on battery.
  # Keeping these values host-local avoids applying zz2's panel settings to zz.
  #
  # `output` is only a hint. The Intel and NVIDIA GPUs take turns owning
  # eDP-1/eDP-2 depending on probe order — it was eDP-2 before the 7.3.1 ->
  # 7.3.4 update and eDP-1 after — so nixos/shared/power.nix resolves the
  # panel from `niri msg outputs` and falls back to the first eDP-*/LVDS*
  # connector it finds. A hardcoded name would work until the next reboot.
  laptop.display = {
    output = "eDP-1";
    backlight = "intel_backlight";
    brightnessAC = 496;
    brightnessBattery = 150;
    modeAC = "3200x2000@165.000";
    modeBattery = "3200x2000@60.001";
  };

  # Disable WiFi power saving while on AC; re-enable it on battery.
  laptop.wifi.interface = "wlp0s20f3";

  system.stateVersion = stateVersion;
}
