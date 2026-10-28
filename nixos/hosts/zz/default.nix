{ ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Host-specific overrides
    ./hostname.nix
    ./modules/gpu.nix
    ./modules/storage.nix

    # Shared NixOS baseline
    ../../shared
  ];

  # zz does not override laptop.display, so the AC/battery display script
  # leaves brightness and mode alone on this host. Add values here if you
  # want the same power-state switching as zz2.

  system.stateVersion = "26.05";
}
