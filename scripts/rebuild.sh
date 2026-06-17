#!/usr/bin/env bash

set -euo pipefail

echo "=== Checking flake ==="
nix flake check

echo "=== Rebuilding (.#main) ==="
sudo nixos-rebuild switch --flake ".#main"

echo "=== Done ==="
