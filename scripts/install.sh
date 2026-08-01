#!/usr/bin/env bash

set -euo pipefail

FLAKE_ROOT="/mnt/persist/system/etc/nixos/nyx"

if [ ! -d "$FLAKE_ROOT" ]; then
  echo "ERROR: Flake not found at $FLAKE_ROOT. Run 'just disko' first." >&2
  exit 1
fi
cd "$FLAKE_ROOT"

echo "=== Installing NixOS (.#uriel) ==="
nixos-install --no-root-passwd --flake ".#uriel" \
  --option extra-substituters "https://nix-community.cachix.org https://vicinae.cachix.org https://cache.nixos-cuda.org" \
  --option extra-trusted-public-keys "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc= cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" \

echo "=== Done. Reboot and run: just rebuild ==="
