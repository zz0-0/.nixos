# Adding packages without rebuilding the whole system

> 对应：`home-manager/shared/packages.nix`、`nixos/shared/*`

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

