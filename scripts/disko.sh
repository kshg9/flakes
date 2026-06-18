#!/usr/bin/env bash

set -euo pipefail

FLAKE_ROOT="${FLAKE_ROOT:-$(pwd)}"

echo "=== Partitioning disk with disko (.#hostMain) ==="
nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/disko/latest -- \
  --mode destroy,format,mount --flake ".#hostMain"

echo "=== Setting root-blank subvolume read-only ==="
mkdir -p /tmp/btrfs_mnt
mount -o subvol=/ /dev/mapper/enc /tmp/btrfs_mnt
btrfs property set /tmp/btrfs_mnt/root-blank ro true
umount /tmp/btrfs_mnt

echo "=== Copying flake to /mnt/persist/system/etc/nixos/zinx ==="
mkdir -p /mnt/persist/system/etc/nixos/zinx
rsync -a --exclude='.git' --exclude='result' --exclude='tmp' "$FLAKE_ROOT/" "/mnt/persist/system/etc/nixos/zinx/"

echo "=== Done. Run: just install ==="
