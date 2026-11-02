#!/usr/bin/env bash
# Build the host, show the closure diff, then switch after confirmation.
# `nixos-rebuild switch` already builds before activating; this wrapper makes
# the pre-build and diff explicit and aborts before touching the running system
# if the build fails.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

assume_yes=false
if [ "${1:-}" = "--yes" ]; then
  assume_yes=true
  shift
fi
host="${1:-zz2}"

./scripts/build-hosts.sh "$host"

echo
echo "==> closure diff for $host"
nix store diff-closures /run/current-system "result-$host" || true

echo
if ! $assume_yes; then
  read -r -p "Switch to $host now? [y/N] " answer
  case "$answer" in
    y | Y | yes | YES) ;;
    *)
      echo "aborted; the running system was not changed."
      exit 0
      ;;
  esac
fi

sudo nixos-rebuild switch --flake ".#$host"
