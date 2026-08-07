# NixOS Configuration

Multi-host NixOS configuration with shared modules and host-specific settings.

## Structure

```
.
├── flake.nix                          # Main flake entry point
├── nixos/                             # NixOS system configurations
│   ├── shared/                        # Shared across all hosts
│   │   ├── audio/pipewire.nix
│   │   ├── display/x11.nix            # X server, libinput, numlock
│   │   ├── display/dms.nix            # DMS greeter (niri compositor)
│   │   ├── programs/                  # (steam.nix removed — disabled)
│   │   ├── boot.nix                   # systemd-boot, kernel, kernel params
│   │   ├── bluetooth.nix
│   │   ├── desktop.nix                # printing, gvfs, udisks2
│   │   ├── dns.nix                    # AdGuardHome + resolv.conf
│   │   ├── fonts.nix
│   │   ├── firmware.nix
│   │   ├── i18n.nix                   # locale, timezone, fcitx5
│   │   ├── network.nix                # NetworkManager, firewall
│   │   ├── nix.nix                    # nix settings, caches
│   │   ├── power.nix                  # power profiles, AC/battery rules
│   │   ├── security.nix               # polkit, gnome-keyring
│   │   └── users.nix
│   └── hosts/
│       ├── zz/                        # Original laptop
│       │   ├── default.nix            # imports shared modules
│       │   ├── hardware-configuration.nix
│       │   ├── hostname.nix
│       │   └── modules/
│       │       ├── gpu.nix            # NVIDIA PRIME (legacy_580)
│       │       └── storage.nix        # /mnt/drive
│       └── zz2/                       # New laptop (Intel i7-358H + RTX 5060)
│           ├── default.nix
│           ├── hardware-configuration.nix
│           ├── hostname.nix
│           ├── security.nix           # fprintd
│           └── modules/
│               ├── gpu.nix            # NVIDIA PRIME (open, latest) + prime-run/wl-mirror
│               ├── peripherals.nix    # WiFi, Goodix touchpad, kernel modules
│               └── goodix-custom-driver.nix  # patched hid-multitouch
└── home-manager/                      # User home configurations
    ├── shared/
    │   ├── host.nix                   # Common imports + home settings
    │   ├── niri.nix                   # Common niri settings/keybinds
    │   ├── packages.nix
    │   ├── portals.nix
    │   ├── shell.nix                  # wezterm, fish, starship, direnv
    │   ├── theme.nix                  # GTK/QT themes, dconf
    │   └── programs/
    │       ├── dms.nix
    │       ├── editor.nix             # zed
    │       └── git.nix
    └── hosts/
        ├── zz/                        # Home config for zz
        │   └── default.nix            # thin: imports shared/host + shared/niri
        └── zz2/                       # Home config for zz2
            ├── default.nix            # thin: imports shared/host + ./niri.nix
            └── niri.nix               # adds multi-GPU niri systemd unit
```

## Usage

### Building NixOS configurations

**For zz (original laptop):**
```bash
sudo nixos-rebuild switch --flake .#zz
```

**For zz2 (new laptop):**
```bash
sudo nixos-rebuild switch --flake .#zz2
```

### Building Home Manager configurations

**For zz:**
```bash
home-manager switch --flake .#zz
```

**For zz2:**
```bash
home-manager switch --flake .#zz2
```

## Per-host power settings

`nixos/shared/power.nix` applies display brightness and refresh-rate changes
on AC/battery switches via a `laptop.display` option. Defaults match zz2
(3200x2000 panel). Override per host:

```nix
laptop.display = {
  brightnessAC = 496;
  brightnessBattery = 150;
  modeAC = "3200x2000@165.000";
  modeBattery = "3200x2000@60.001";
};
```

## Setting up a new host

1. Boot NixOS installer, run `nixos-generate-config`
2. Copy `/etc/nixos/hardware-configuration.nix` to `nixos/hosts/<name>/hardware-configuration.nix`
3. Update `nixos/hosts/<name>/modules/gpu.nix` with correct PCI bus IDs (`lspci | grep -E "VGA|3D"`)
4. Add host-specific modules (GPU, storage) and import them from `nixos/hosts/<name>/default.nix`
5. Create `home-manager/hosts/<name>/default.nix`:
   ```nix
   { ... }: {
     imports = [ ../../shared/host.nix ../../shared/niri.nix ];
   }
   ```
6. Add one entry to the `hosts` attrset in `flake.nix` (nixosConfigurations,
   homeConfigurations and checks are generated from it automatically)
7. Build with: `sudo nixos-rebuild switch --flake .#<name>`

## Validating the configuration

`nix flake check` builds and validates both hosts (NixOS toplevel + Home
Manager activation). Run it after `nix flake update` to catch package
removals or evaluation errors before rebuilding:

```bash
nix flake check
```

## Niri Build Fix

The niri package is built with tests disabled (`doCheck = false`) because some
systems fail the test suite with EGL display issues. `niriPkg` is defined once
in `flake.nix` and shared between the NixOS `programs.niri` module and Home
Manager via `specialArgs`.

## Nix caches

The niri binary cache (`https://niri.cachix.org`) is configured in
`nixos/shared/nix.nix` under `substituters`, alongside the niri cache key.
