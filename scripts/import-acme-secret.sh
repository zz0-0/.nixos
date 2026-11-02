#!/usr/bin/env bash
# Import the existing root-only Aliyun credentials into an encrypted sops file.
# Run this inside `nix develop` (sops must be on PATH) and with sudo available.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

key="$HOME/.config/sops/age/keys.txt"
if [ ! -s "$key" ]; then
  echo "error: no age key at $key" >&2
  echo "create one with: nix shell nixpkgs#age -c age-keygen -o $key" >&2
  exit 1
fi

if ! command -v sops >/dev/null 2>&1; then
  echo "error: sops is not on PATH; run this inside 'nix develop'" >&2
  exit 1
fi

source_file="/var/lib/acme-sh/aliyun.env"
if [ ! -r "$source_file" ]; then
  echo "Reading $source_file with sudo (it is root-only)."
fi

mkdir -p secrets/acme-sh
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
sudo cat "$source_file" > "$tmp"

sops --encrypt \
  --input-type dotenv \
  --output-type dotenv \
  --filename-override secrets/acme-sh/aliyun.env \
  "$tmp" > secrets/acme-sh/aliyun.env

echo "Wrote secrets/acme-sh/aliyun.env"
echo
echo "Next steps:"
echo "  1. git add secrets/acme-sh/aliyun.env"
echo "  2. In nixos/shared/acme-sh.nix, add the sops.secrets block"
echo "     (format = \"dotenv\") and set"
echo "     EnvironmentFile = config.sops.secrets.\"acme-sh/aliyun.env\".path;"
echo "  3. ./scripts/build-hosts.sh zz2 && sudo nixos-rebuild switch --flake .#zz2"
