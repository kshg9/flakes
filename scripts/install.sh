#!/usr/bin/env bash

set -euo pipefail

FLAKE_ROOT="/mnt/persist/system/etc/nixos/zinx"

GREEN='\e[1;32m'
RED='\e[1;31m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
NC='\e[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# ── 1. Validate environment ────────────────────────────────────────
validate() {
  if [ ! -d "$FLAKE_ROOT" ]; then
    error "Flake not found at $FLAKE_ROOT. Run 'just disko' first."
  fi
  info "Found flake at $FLAKE_ROOT"
  cd "$FLAKE_ROOT"
}

# ── 2. Host discovery ──────────────────────────────────────────────
discover_hosts() {
  local hosts_json
  info "Discovering hosts..."

  if ! hosts_json=$(nix --extra-experimental-features "nix-command flakes" flake show --json 2>/dev/null); then
    error "Failed to run 'nix flake show'."
  fi

  mapfile -t HOSTS < <(echo "$hosts_json" | jq -r '.nixosConfigurations | keys[]')
  if [ "${#HOSTS[@]}" -eq 0 ]; then
    error "No nixosConfigurations found."
  fi
}

# ── 3. Set user password ───────────────────────────────────────────
set_user_passwd() {
  if ! command -v mkpasswd &>/dev/null; then
    error "'mkpasswd' not found. Cannot set user password."
  fi

  echo -e "${GREEN}Set your user login password:${NC}"
  while true; do
    read -rsp "Enter password: " user_pass; echo
    read -rsp "Confirm password: " user_pass_confirm; echo

    if [ "$user_pass" != "$user_pass_confirm" ]; then
      echo "Passwords do not match. Try again."
    else
      user_passwd_hash=$(echo "$user_pass" | mkpasswd -m sha-512 -s || error "Failed to generate password hash.")
      success "Password confirmed."
      break
    fi
  done
}

# ── Main ───────────────────────────────────────────────────────────
main() {
  validate
  discover_hosts

  echo -e "${BLUE}Select target host:${NC}"
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

  set_user_passwd

  info "Patching password into general.nix..."
  sed -i "/initialHashedPassword/c\      initialHashedPassword = \"$user_passwd_hash\";" ./nixos/features/general.nix

  info "Installing NixOS for host '$SELECTED_HOST'..."
  nixos-install --no-root-passwd --flake ".#${SELECTED_HOST}"

  success "Installation complete. Reboot and run: just rebuild"
}

main "$@"
