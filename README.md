# NixOS Configuration

Multi-host NixOS configuration with shared modules and host-specific settings.

## Structure

```
.
├── flake.nix                          # Main flake entry point
├── nixos/                             # NixOS system configurations
│   ├── modules/
│   │   └── shared/                    # Shared across all hosts
│   │       ├── boot.nix
│   │       ├── dns.nix
│   │       ├── fonts.nix
│   │       ├── hardware.nix
│   │       ├── hardware/
│   │       │   ├── bluetooth.nix
│   │       │   └── gpu.nix
│   │       ├── i18n.nix
│   │       ├── nix.nix
│   │       ├── programs/
│   │       │   └── steam.nix
│   │       ├── security.nix
│   │       ├── services.nix
│   │       └── users.nix
│   └── hosts/
│       ├── zz/                        # Original laptop
│       │   ├── default.nix
│       │   ├── hardware-configuration.nix
│       │   └── modules/
│       │       ├── hardware/
│       │       │   ├── bluetooth.nix
│       │       │   └── gpu.nix
│       │       ├── network.nix
│       │       └── storage.nix
│       └── zz2/                       # New laptop (Intel + RTX 5060)
│           ├── default.nix
│           ├── hardware-configuration.nix
│           └── modules/
│               ├── hardware/
│               │   ├── bluetooth.nix
│               │   └── gpu.nix
│               ├── network.nix
│               └── storage.nix
└── home-manager/                      # User home configurations
    ├── shared/                        # Shared across all hosts
    │   ├── packages.nix
    │   ├── portals.nix
    │   ├── programs/
    │   │   ├── dms.nix
    │   │   ├── editor.nix
    │   │   ├── git.nix
    │   │   └── niri.nix
    │   ├── services.nix
    │   ├── services/
    │   │   ├── background.nix
    │   │   └── user-services.nix
    │   ├── shell.nix
    │   ├── theme.nix
    │   └── xdg.nix
    └── hosts/
        ├── zz/                        # Home config for zz
        │   └── default.nix
        └── zz2/                       # Home config for zz2
            └── default.nix
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

### Setting up zz2 (new laptop)

1. Boot NixOS installer on the new laptop
2. Run `nixos-generate-config` to generate hardware configuration
3. Copy the generated `/etc/nixos/hardware-configuration.nix` to `nixos/hosts/zz2/hardware-configuration.nix`
4. Update `nixos/hosts/zz2/modules/hardware/gpu.nix` with correct PCI bus IDs:
   ```bash
   lspci | grep -E "VGA|3D"
   ```
5. Update `nixos/hosts/zz2/modules/storage.nix` with actual disk UUIDs
6. Build the configuration:
   ```bash
   sudo nixos-rebuild switch --flake .#zz2
   ```

## Niri Build Fix

The niri flake has been patched to disable failing tests (`doCheck = false`) that cause build failures on some systems with EGL display issues. This is applied via an overlay in `flake.nix`.

## Adding New Hosts

To add a new host (e.g., `zz3`):

1. Create `nixos/hosts/zz3/` directory with:
   - `default.nix` (import shared modules + host-specific ones)
   - `hardware-configuration.nix` (auto-generated)
   - `modules/` for host-specific settings (network, storage, GPU)

2. Create `home-manager/hosts/zz3/default.nix`

3. Add entries in `flake.nix`:
   - Add to `nixosConfigurations.zz3`
   - Add to `homeConfigurations.zz3`

4. Build with: `sudo nixos-rebuild switch --flake .#zz3`
