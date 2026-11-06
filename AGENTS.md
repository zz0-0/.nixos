# Maintaining this machine

This repo is the NixOS + Home Manager configuration for hosts `zz2` (laptop) and
`zz`. It is the only place a machine-wide change is made.

## The loop

1. **Edit the right file**
   - user CLI packages → `home-manager/shared/packages.nix`
   - shell/editor/desktop program → `home-manager/shared/programs/*.nix`
   - system service, driver, kernel, boot → `nixos/shared/*.nix`
   - one host only → `nixos/hosts/<host>/**`
2. **Build before touching the running system**

   ```bash
   ./scripts/build-hosts.sh zz2
   ```

3. **Switch** — needs `sudo`; ask the user to run or confirm:

   ```bash
   ./scripts/switch-host.sh zz2
   ```

4. **Verify**, then **commit and push**. The GitHub copy is what the other host
   and future rebuilds depend on; an unpushed config exists on one disk.

## What not to do

- **Never** run a standalone `home-manager switch`. Home Manager is embedded in
  the NixOS module; a standalone switch creates a second profile.
- Do not decrypt a secret into a project or paste a value into a flake. Use the
  sops flow.
- Do not switch a host you have not built, and do not switch `zz` from `zz2`
  without confirming which host is meant.
- A change that needs a reboot is not done until the reboot is named.
