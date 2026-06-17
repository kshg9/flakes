#!/usr/bin/env bash

set -euo pipefail

PAMT=sudo

GREEN='\e[1;32m'
RED='\e[1;31m'
BLUE='\e[1;34m'
NC='\e[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# ── 1. Validate flake ──────────────────────────────────────────────
validate_flake() {
  info "Validating flake configuration..."
  nix flake check
  success "Flake check passed."
}

# ── 2. Host discovery ──────────────────────────────────────────────
discover_hosts() {
  local hosts_json
  info "Discovering hosts..."

  if ! hosts_json=$(nix flake show --json 2>/dev/null); then
    error "Failed to run 'nix flake show'."
  fi

  mapfile -t HOSTS < <(echo "$hosts_json" | jq -r '.nixosConfigurations | keys[]')
  if [ "${#HOSTS[@]}" -eq 0 ]; then
    error "No nixosConfigurations found."
  fi
}

# ── Main ───────────────────────────────────────────────────────────
main() {
  validate_flake

  discover_hosts

  echo -e "${BLUE}Select host to rebuild:${NC}"
  for i in "${!HOSTS[@]}"; do
    echo "$((i + 1)). ${HOSTS[$i]}"
  done

  local idx
  while true; do
    read -rp "Choice (number): " idx
    if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le "${#HOSTS[@]}" ]; then
      break
    fi
    echo "Invalid choice, try again."
  done
  SELECTED_HOST="${HOSTS[$((idx - 1))]}"

  info "Rebuilding $SELECTED_HOST..."
  $PAMT nixos-rebuild switch --flake ".#${SELECTED_HOST}"

  success "Rebuild complete."
}

main "$@"
