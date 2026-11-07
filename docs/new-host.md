# Setting up a new host

> 对应：`nixos/hosts/`、`home-manager/hosts/`、`flake.nix`

1. Boot the NixOS installer and run `nixos-generate-config`.
2. Copy `/etc/nixos/hardware-configuration.nix` to
   `nixos/hosts/<name>/hardware-configuration.nix`.
3. Add host-specific modules (GPU, storage, touchpad, etc.).
4. Create `nixos/hosts/<name>/default.nix`:
   ```nix
   { ... }: {
     imports = [
       ./hardware-configuration.nix
       ./hostname.nix
       ./modules/gpu.nix
       ../../shared
     ];
     system.stateVersion = "26.05";
   }
   ```
5. Create `home-manager/hosts/<name>/default.nix`:
   ```nix
   { ... }: {
     imports = [ ../../shared/host.nix ../../shared/niri.nix ];
   }
   ```
6. Add one entry to the `hosts` attrset in `flake.nix`. NixOS
   configurations, Home Manager configurations, and checks are generated from
   it automatically.
7. Build with: `sudo nixos-rebuild switch --flake .#<name>`.

Keep host-specific assumptions out of `nixos/shared/`. If a setting only makes
sense for one panel, GPU driver, or adapter, put it in that host's module.

