# Secrets (sops-nix)

> 对应：`secrets/`、`nixos/shared/sops.nix`、`scripts/import-acme-secret.sh`

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

