#!/usr/bin/env bash

set -euo pipefail

FLAKE_ROOT="/mnt/persist/system/etc/nixos/zinx"

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
nixos-install --no-root-passwd --flake ".#main"

echo "=== Done. Reboot and run: just rebuild ==="
