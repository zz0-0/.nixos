# NixOS Configuration

Multi-host NixOS configuration with shared modules and host-specific settings.

## Structure

```
.
├── flake.nix                          # Flake entry point, hosts, checks, devshell
├── nixos/
│   ├── shared/
│   │   ├── default.nix                # Aggregator: imports the shared baseline
│   │   ├── audio/pipewire.nix
│   │   ├── display/x11.nix            # X server, libinput, keyboard layout
│   │   ├── display/dms.nix            # DMS greeter (niri compositor)
│   │   ├── programs/                  # evolution, Steam
│   │   ├── boot.nix                   # systemd-boot, kernel, boot timeout
│   │   ├── bluetooth.nix
│   │   ├── desktop.nix                # printing, gvfs, udisks2
│   │   ├── dns.nix                    # AdGuardHome + resolv.conf
│   │   ├── fonts.nix
│   │   ├── firmware.nix
│   │   ├── i18n.nix                   # locale, timezone, fcitx5
│   │   ├── network.nix                # NetworkManager, firewall
│   │   ├── nix.nix                    # nix settings, caches, GC/optimise
│   │   ├── power.nix                  # power profiles, AC/battery display service
│   │   ├── security.nix               # polkit, gnome-keyring
│   │   └── users.nix
│   └── hosts/
│       ├── zz/                        # Original laptop
│       │   ├── default.nix            # imports hardware + ../../shared
│       │   ├── hardware-configuration.nix
│       │   ├── hostname.nix
│       │   └── modules/
│       │       ├── gpu.nix            # NVIDIA PRIME (legacy_580), i915 options
│       │       └── storage.nix        # /mnt/drive
│       └── zz2/                       # New laptop (Core Ultra 7 356H + RTX 5060)
│           ├── default.nix
│           ├── hardware-configuration.nix
│           ├── hostname.nix
│           ├── security.nix           # fprintd
│           └── modules/
│               ├── gpu.nix            # NVIDIA PRIME (open, latest) + prime-run/wl-mirror
│               ├── peripherals.nix    # WiFi, Goodix touchpad, I2C modules
│               ├── goodix-custom-driver.nix  # patched hid-multitouch
│               └── btintel-pcie-fix.nix      # NULL-hdev fix as out-of-tree module
└── home-manager/
    ├── shared/
    │   ├── host.nix                   # Common imports + home settings
    │   ├── niri.nix                   # Common niri settings/keybinds
    │   ├── packages.nix
    │   ├── shell.nix                  # wezterm, fish, starship, direnv
    │   ├── theme.nix                  # GTK/QT themes, dconf
    │   └── programs/
    │       ├── dms.nix
    │       ├── editor.nix             # zed, emacs
    │       ├── evolution.nix
    │       ├── git.nix
    │       └── teams.nix
    └── hosts/
        ├── zz/
        │   └── default.nix            # imports shared/host + shared/niri
        └── zz2/
            ├── default.nix            # imports shared/host + ./niri
            └── niri.nix               # niri user unit for the multi-GPU host
```

## Usage

### Building NixOS configurations

```bash
sudo nixos-rebuild switch --flake .#zz
sudo nixos-rebuild switch --flake .#zz2
```

Use `nixos-rebuild` as the single entry point. Home Manager is embedded as a
NixOS module (`home-manager.useGlobalPkgs = true`, `useUserPackages = true`).
The flake also exposes `homeConfigurations` for standalone-HM tooling, but do
not mix `home-manager switch` with the NixOS-managed profile: it creates a
second profile and makes activation order confusing.

### dGPU runtime power on zz2

NVIDIA 615 runs probe in an `nv-probe` kthread. On Linux 7.3, kthreads start
with an empty nullfs root, so the driver's `filp_open()` on
`/sys/bus/pci/devices/<id>/config` fails and the driver disables runtime D3.
This is why `/proc/driver/nvidia/gpus/*/power` said
`Runtime D3 status: Not supported` and the RTX 5060 never left D0.

`nixos/hosts/zz2/modules/gpu.nix` applies the CachyOS fix
(`nixos/hosts/zz2/patches/nvidia-rtd3-7.3.patch`) to the NVIDIA open module.
It wraps the lookup in `scoped_with_init_fs()` on 7.3+, so RTD3 reports
`Enabled (fine-grained)` again. The dGPU then enters D3cold when idle and
wakes automatically when `prime-run` or a game needs it.

After switching and rebooting, verify at idle:

```bash
cat /sys/bus/pci/devices/0000:02:00.0/power/runtime_status
cat /sys/bus/pci/devices/0000:02:00.0/power/runtime_suspended_time
nvidia-smi --query-gpu=name,pstate,power.draw --format=csv
cat /proc/driver/nvidia/gpus/*/power
```

## Boot time

`boot.loader.timeout = 2` is set in `nixos/shared/boot.nix`. The old default
was 5 seconds, which was the largest single chunk of boot time. For reference,
the zz2 boot breakdown before this change was:

```
firmware 5.43s + loader 6.36s + kernel 1.81s + initrd 2.70s + userspace 5.07s
```

The stock WiFi/Bluetooth modules are left to udev autoload instead of
`boot.kernelModules`, so `iwlmvm`'s firmware load no longer blocks
`systemd-modules-load`. The custom `btintel_pcie_fixed` and
`goodix-gt7868q` modules remain explicit because they are not autoloaded.

## Per-host power settings

`nixos/shared/power.nix` applies display brightness and refresh-rate changes
on AC/battery switches. The option defaults are intentionally `null` — a host
opts in by setting values. zz2 sets its 3200x2000 panel values in
`nixos/hosts/zz2/default.nix`; zz leaves them unset.

```nix
laptop.display = {
  output = "eDP-1";
  backlight = "intel_backlight";
  brightnessAC = 496;
  brightnessBattery = 150;
  modeAC = "3200x2000@165.000";
  modeBattery = "3200x2000@60.001";
};
```

The udev rule now only triggers `power-state-change.service`; the service sets
brightness and the power profile. A user service (`niri-display-power`) applies
the refresh rate after niri starts, which fixes the old boot-on-battery case
where the udev event ran before the compositor existed.

## Adding packages without rebuilding the whole system

Packages in `home-manager/shared/packages.nix` are part of the Home Manager
generation, which is embedded in the NixOS generation. Changing that list
still triggers `nixos-rebuild`, though usually only the activation/closure
changes — not a full rebuild of everything.

For occasional, heavy, or experimental GUI apps, avoid putting them in the
system closure:

```bash
# Run once, no profile entry
nix run nixpkgs#blender

# Install into the user profile, outside the NixOS generation
nix profile install nixpkgs#blender
nix profile upgrade blender
nix profile remove blender
```

Keep the declarative lists for things you want on every login (desktop,
terminal, browser, drivers, CLI tools). Use `nix profile` for the long tail.
This keeps `nixos-rebuild` fast and keeps the system reproducible.

Build speed also benefits from:

- `nix.settings.auto-optimise-store` is off; `nix.optimise` runs weekly.
- `nixpkgs-wayland` was removed from the substituters; it was not serving the
  niri/dms packages used here.
- The unused `khal` overlay was removed.
- The custom kernel modules are built only for the selected kernel.

## Setting up a new host

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

## Validating the configuration

`nix flake check` builds and validates both hosts (NixOS toplevel + Home
Manager activation). It is useful after `nix flake update`; it is not needed
for every switch.

```bash
nix flake check
```

## Development shell

The repo uses a small inline `devShells.x86_64-linux.default` in `flake.nix`:
`nil`, `nixd`, `statix`, `nixfmt`, `deadnix`, and the matching `home-manager`.
`.envrc` uses `use flake`, so `direnv allow` is enough.

Run `nix fmt` to format the tree with `nixfmt`.

## Architecture notes

This is a declarative infrastructure repository, not an application. DDD and
"clean architecture" do not map cleanly onto it; the useful equivalent is:

- **Composition root**: `nixos/hosts/<name>` and `home-manager/hosts/<name>`.
- **Reusable modules**: `nixos/shared` and `home-manager/shared`; these should
  expose options and should not depend on a specific host.
- **Platform quirks**: host modules (`gpu.nix`, `peripherals.nix`, custom
  drivers) rather than shared files.
- **Tooling**: the devshell is separate from the system configuration.
- **Checks**: `nix flake check` is the integration test.

The main architectural rule is dependency direction: hosts may import shared
modules, but shared modules must not assume a host. If a shared module needs
per-host behaviour, add an option (as `laptop.display` and `laptop.power.adapter`
now do) and set it in the host module.
