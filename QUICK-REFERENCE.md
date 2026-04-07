# Quick Reference: Multi-Host NixOS Setup

## Building Configurations

### For zz (original laptop)
```bash
# Full system
sudo nixos-rebuild switch --flake .#zz

# Home manager only
home-manager switch --flake .#zz
```

### For zz2 (new laptop - Intel + RTX 5060)
```bash
# Full system
sudo nixos-rebuild switch --flake .#zz2

# Home manager only
home-manager switch --flake .#zz2
```

## Setting up zz2 (New Laptop)

1. **Boot NixOS installer** on the new laptop

2. **Generate hardware configuration**:
   ```bash
   nixos-generate-config --no-filesystems
   ```
   This creates `/etc/nixos/hardware-configuration.nix`

3. **Get PCI Bus IDs for GPUs**:
   ```bash
   lspci | grep -E "VGA|3D"
   ```
   Note the Bus IDs (e.g., `00:02.0` for Intel, `01:00.0` for NVIDIA)
   Convert to format: `PCI:0:2:0` and `PCI:1:0:0`

4. **Copy hardware-configuration.nix** to this repo:
   ```bash
   cp /etc/nixos/hardware-configuration.nix /path/to/nixos/nixos/hosts/zz2/
   ```

5. **Update zz2-specific files**:
   - `nixos/hosts/zz2/hardware-configuration.nix` - replace with generated file
   - `nixos/hosts/zz2/modules/hardware/gpu.nix` - update Bus IDs from step 3
   - `nixos/hosts/zz2/modules/storage.nix` - update disk UUIDs if needed

6. **Build the configuration**:
   ```bash
   sudo nixos-rebuild switch --flake .#zz2
   ```

## Niri Build Fix

The niri flake build issue (failing EGL tests) is fixed by disabling tests via overlay in `flake.nix`:
```nix
niriOverlay = final: prev: {
  niri = inputs.niri.packages.${system}.niri-unstable.overrideAttrs (_: {
    doCheck = false;
  });
};
```

## Architecture

```
nixos/                        # NixOS system configs
├── modules/shared/            # Shared NixOS modules
│   ├── boot.nix
│   ├── dns.nix
│   ├── gpu.nix (default)
│   └── ...
└── hosts/
    ├── zz/                   # zz host
    │   └── modules/          # zz-specific (GPU, network, storage)
    └── zz2/                  # zz2 host
        └── modules/          # zz2-specific

home-manager/                 # User home configs
├── shared/modules/           # Shared HM modules
└── hosts/
    ├── zz/                   # zz home
    └── zz2/                  # zz2 home
```

## Key Differences: zz vs zz2

| Setting          | zz                    | zz2                   |
|------------------|-----------------------|-----------------------|
| Hostname         | zz                    | zz2                   |
| GPU Driver       | legacy_580            | latest (RTX 5060)     |
| Hardware Config  | zz-specific UUIDs     | zz2-specific UUIDs    |
| External Storage | /mnt/drive (UUID)     | TBD                   |

## Common Tasks

### Update flake inputs
```bash
nix flake update
```

### Check what will be built (dry run)
```bash
nixos-rebuild build --flake .#zz2 --dry-run
```

### Rollback to previous generation
```bash
sudo nixos-rebuild switch --flake .#zz2 --rollback
```
