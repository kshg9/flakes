#!/usr/bin/env bash
# Build the installer ISO (minimal graphical, fullscreen kitty session) for this flake.
#   scripts/build-iso.sh            → ./result/iso/flakes-installer.iso
#   scripts/build-iso.sh --out-link /tmp/iso
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/.."

out_link="${1:-result}"
nix --extra-experimental-features 'nix-command flakes' build \
  --out-link "$out_link" \
  '.#nixosConfigurations.installer.config.system.build.isoImage'

echo
echo "ISO ready: $out_link/iso/flakes-installer.iso"
echo "Write to USB: sudo dd if=$out_link/iso/flakes-installer.iso of=/dev/sdX bs=1M status=progress"
