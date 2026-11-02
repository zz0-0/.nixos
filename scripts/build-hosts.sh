#!/usr/bin/env bash
# Build NixOS systems before switching. This catches build failures in kernel
# modules, patches, and packages that `nix flake check --no-build` cannot see.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

hosts=("$@")
if [ ${#hosts[@]} -eq 0 ]; then
  hosts=(zz2 zz)
fi

for host in "${hosts[@]}"; do
  echo "==> building nixosConfigurations.${host}"
  nix build --out-link "result-${host}" \
    ".#nixosConfigurations.${host}.config.system.build.toplevel"
  echo "==> built $(readlink -f "result-${host}")"
done

echo
echo "Builds succeeded. Review the closure diff before switching:"
for host in "${hosts[@]}"; do
  echo "  nix store diff-closures /run/current-system result-${host}"
done
