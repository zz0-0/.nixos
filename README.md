# NixOS Configuration

Multi-host NixOS configuration with shared modules and host-specific settings.

## Structure

```
.
├── .sops.yaml                          # age recipients for secrets/
├── secrets/                            # encrypted sops payloads
├── flake.nix                          # Flake entry point, hosts, checks, devshell
├── scripts/
│   ├── build-hosts.sh                 # build both hosts before switching
│   └── switch-host.sh                 # build, diff, confirm, then switch
├── nixos/
│   ├── shared/
│   │   ├── default.nix                # Aggregator: imports the shared baseline
│   │   ├── acme-sh.nix                # acme.sh renewal + Aliyun deploy
│   │   ├── audio/pipewire.nix
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
│   │   ├── sops.nix                   # sops-nix age key
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
    │       ├── dsh.nix                # dsh web UI + launcher
    │       ├── editor.nix             # zed, Emacs (doom-acario-dark)
    │       ├── evolution.nix
    │       ├── git.nix
    │       ├── pbz.nix                # Phantom Blade Zero helpers
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

Build first — evaluation alone does not catch kernel-module, patch, or package
build failures:

```bash
./scripts/build-hosts.sh zz2          # current laptop
# ./scripts/build-hosts.sh            # both hosts
nix store diff-closures /run/current-system result-zz2
sudo nixos-rebuild switch --flake .#zz2
```

`zz` uses the same sequence with `.#zz` and `result-zz`.

Or use the wrapper, which builds, shows the closure diff, asks for
confirmation, switches, and then collects system + Home Manager generations
older than 7 days:

```bash
./scripts/switch-host.sh zz2
GC_MAX_AGE=14d ./scripts/switch-host.sh zz2   # keep two weeks
```

The weekly `nix.gc` timers remain; the wrapper just makes cleanup happen after
each successful switch too. It keeps generations newer than the cutoff for
rollback.

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

systemd-boot can also store an explicit menu timeout in the `LoaderConfigTimeout`
EFI variable, and that NVRAM value overrides `loader.conf`. It survives
rebuilds and firmware updates, so the menu can silently go back to a longer
timeout even though this file says 2. `nixos/shared/boot.nix` clears the
variable as part of bootloader installation, making the declarative value
authoritative. To inspect it manually:

```bash
od -An -tx1 -v /sys/firmware/efi/efivars/LoaderConfigTimeout-*
```

The stock WiFi/Bluetooth modules are left to udev autoload instead of
`boot.kernelModules`, so `iwlmvm`'s firmware load no longer blocks
`systemd-modules-load`. The custom `btintel_pcie_fixed` and
`goodix-gt7868q` modules remain explicit because they are not autoloaded.

## Emacs

`home-manager/shared/programs/editor.nix` installs vanilla Emacs 31 (pgtk)
with `envrc` and the built-in Eglot LSP client. `envrc-global-mode` loads the
nearest `.envrc` per buffer, so Eglot finds the language servers provided by
the devshell flake instead of requiring system-wide installs. No generated
Emacs files are needed: `envrc` reads the project `.envrc` directly.

Environment selection is per buffer: `envrc` walks up from the buffer's
`default-directory` to the nearest `.envrc`. Starting Emacs from a project
directory (or opening a file or directory there) loads that devshell
automatically. The initial `*scratch*` buffer uses the directory Emacs was
launched from; launched from the desktop it is usually `$HOME`, so the project
environment is loaded when you open a project file. The modeline shows
`envrc[on]`; run `direnv allow` once per project if it shows `denied`.

Language modes/servers wired up: Nix (`nixd`), Python
(`basedpyright-langserver`), Rust/Bevy (`rust-analyzer`), Dart/Flutter
(`dart language-server`), Java (`jdtls`), LaTeX (`texlab`), and Markdown
(`markdown-oxide`). TypeScript, YAML and TOML get modes only. Format-on-save
uses Apheleia (`nixfmt`, `ruff`, `rustfmt`, `dart format`, `latexindent`);
Java is formatted through Eglot/jdtls.

Eglot connects on the next command after the devshell environment finishes
loading; if it does not, `M-x eglot` starts it manually. PostgreSQL keeps the
built-in `sql-mode` (`M-x sql-postgres`); the video devshell has no TypeScript
language server, so `.ts` files get `typescript-mode` syntax only. The
devshell flake itself lives in `~/.devshell`; it supplies language toolchains,
not Emacs-specific files.

## Firmware updates

`services.fwupd.enable` is on. fwupd refreshes LVFS metadata automatically via
`fwupd-refresh.timer`, but firmware/BIOS installation is intentionally manual:

```bash
sudo fwupdmgr get-devices
sudo fwupdmgr get-updates
sudo fwupdmgr update
```

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

`laptop.wifi.interface` opts into the same service toggling WiFi power saving
(off on AC, on on battery). zz2 sets it to `wlp0s20f3`.

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

## Secrets (sops-nix)

System secrets live in `secrets/` and are encrypted with sops-nix + age.
`sops-nix` is imported by `flake.nix`; `nixos/shared/sops.nix` points it at the
age key `~/.config/sops/age/keys.txt`. The public key is in `.sops.yaml`; the
private key never goes in the repo. **Back the private key up** — without it the
encrypted secrets cannot be recovered.

The Aliyun env is stored encrypted at `secrets/acme-sh/aliyun.env` and
`nixos/shared/acme-sh.nix` reads it through sops-nix:

```nix
sops.secrets."acme-sh/aliyun.env" = {
  sopsFile = ../../secrets/acme-sh/aliyun.env;
  format = "dotenv";
  owner = "root";
  mode = "0400";
};

# inside systemd.services.acme-sh.serviceConfig:
EnvironmentFile = config.sops.secrets."acme-sh/aliyun.env".path;
```

If the credentials are rotated, re-import them:

```bash
nix develop
./scripts/import-acme-secret.sh
git add secrets/acme-sh/aliyun.env
```

The script reads `/var/lib/acme-sh/aliyun.env` with sudo and rewrites the
encrypted file. Later edits use
`sops --input-type dotenv --output-type dotenv secrets/acme-sh/aliyun.env`.
The `sops` and `age` tools are in the repo devshell.

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
Manager activation). It is useful after `nix flake update`.

```bash
nix flake check
```

For the normal pre-switch check, use `./scripts/build-hosts.sh <host>`: it
builds only the host you are about to switch and is faster than the full flake
check. CI builds both hosts on every push. `nix flake check --no-build` is the
fast evaluation-only variant.

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
