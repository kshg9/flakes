#!/usr/bin/env bash

set -euo pipefail

FLAKE_ROOT="/mnt/persist/system/etc/nixos/nyx"

if [ -d "$FLAKE_ROOT" ]; then
  cd "$FLAKE_ROOT"
elif [ -f "flake.nix" ]; then
  :
else
  echo "ERROR: Not in a flake directory and $FLAKE_ROOT not found. Run 'just disko' first." >&2
  exit 1
fi

echo "=== Dry-run of system build (.#main) ==="
sudo nix --extra-experimental-features "nix-command flakes" build --dry-run --no-write-lock-file \
  --option extra-substituters "https://nix-community.cachix.org https://vicinae.cachix.org https://cache.nixos-cuda.org" \
  --option extra-trusted-public-keys "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc= cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" \
  '.#nixosConfigurations.main.config.system.build.toplevel'

echo "=== Done ==="
