#!/usr/bin/env bash
# Build the host, show the closure diff, then switch after confirmation.
# `nixos-rebuild switch` already builds before activating; this wrapper makes
# the pre-build and diff explicit and aborts before touching the running system
# if the build fails. After a successful switch it collects NixOS and Home
# Manager generations older than GC_MAX_AGE (default 7d).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

assume_yes=false
if [ "${1:-}" = "--yes" ]; then
  assume_yes=true
  shift
fi
host="${1:-zz2}"
gc_age="${GC_MAX_AGE:-7d}"

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

echo
echo "==> collecting old NixOS and Home Manager generations (older than $gc_age)"
if ! sudo nix-collect-garbage --delete-older-than "$gc_age"; then
  echo "warning: system GC failed; the switch itself succeeded" >&2
fi
if ! nix-collect-garbage --delete-older-than "$gc_age"; then
  echo "warning: user GC failed; the switch itself succeeded" >&2
fi
