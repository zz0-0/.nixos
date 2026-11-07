# Architecture notes

> 对应：`nixos/shared/`、`nixos/hosts/`

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
