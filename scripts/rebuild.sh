#!/usr/bin/env bash

set -euo pipefail

echo "=== Checking flake ==="
nix flake check

echo "=== Rebuilding (.#uriel) ==="
sudo nixos-rebuild switch --flake ".#uriel"

echo "=== Done ==="
