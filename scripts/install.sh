#!/usr/bin/env bash

set -euo pipefail

FLAKE_ROOT="/mnt/persist/system/etc/nixos/nyx"

if [ ! -d "$FLAKE_ROOT" ]; then
  echo "ERROR: Flake not found at $FLAKE_ROOT. Run 'just disko' first." >&2
  exit 1
fi
cd "$FLAKE_ROOT"

echo "=== Set your user login password ==="
while true; do
  read -rsp "Enter password: " user_pass; echo
  read -rsp "Confirm password: " user_pass_confirm; echo
  [ "$user_pass" = "$user_pass_confirm" ] && break
  echo "Passwords do not match. Try again."
done

passwd_hash=$(echo "$user_pass" | mkpasswd -m sha-512 -s)

echo "=== Patching password into general.nix ==="
sed -i "/initialHashedPassword/c\      initialHashedPassword = \"$passwd_hash\";" ./nixos/features/general.nix

echo "=== Installing NixOS (.#main) ==="
export NIX_CONFIG="extra-substituters = https://nix-community.cachix.org https://vicinae.cachix.org https://cache.nixos-cuda.org
extra-trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc= cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
nixos-install --no-root-passwd --flake ".#main"

echo "=== Done. Reboot and run: just rebuild ==="
