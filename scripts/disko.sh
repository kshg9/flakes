#!/usr/bin/env bash

set -euo pipefail

FLAKE_ROOT="${FLAKE_ROOT:-$(pwd)}"

GREEN='\e[1;32m'
RED='\e[1;31m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
NC='\e[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

check_deps() {
  for cmd in nix jq; do
    if ! command -v "$cmd" &>/dev/null; then
      error "Missing required command: $cmd"
    fi
  done
}

# ── 1. Host discovery ──────────────────────────────────────────────
discover_hosts() {
  local hosts_json
  info "Scanning for NixOS configurations..."

  if ! hosts_json=$(nix --extra-experimental-features "nix-command flakes" flake show --json 2>/dev/null); then
    error "Failed to run 'nix flake show'. Is this a valid flake?"
  fi

  mapfile -t HOSTS < <(echo "$hosts_json" | jq -r '.nixosConfigurations | keys[]')
  if [ "${#HOSTS[@]}" -eq 0 ]; then
    error "No nixosConfigurations found in flake."
  fi
}

# ── 2. Disko layout discovery ─────────────────────────────────────
discover_layouts() {
  local layouts_json
  info "Scanning for disko configurations..."

  if ! layouts_json=$(nix --extra-experimental-features "nix-command flakes" flake show --json 2>/dev/null); then
    error "Failed to run 'nix flake show'."
  fi

  mapfile -t LAYOUTS < <(echo "$layouts_json" | jq -r '.diskoConfigurations | keys[]' 2>/dev/null)
  if [ "${#LAYOUTS[@]}" -eq 0 ]; then
    warn "No diskoConfigurations found in flake. Falling back to manual layout file selection."

    local layout_dir="${FLAKE_ROOT}/nixos/hosts"
    while IFS= read -r -d $'\0' file; do
      LAYOUTS+=("$file")
    done < <(find "$layout_dir" -name "disko.nix" -print0 2>/dev/null)

    if [ "${#LAYOUTS[@]}" -eq 0 ]; then
      error "No disko layouts found (neither diskoConfigurations nor disko.nix files)."
    fi
  fi
}

# ── 3. User selection ──────────────────────────────────────────────
select_option() {
  local prompt="$1"; shift
  local -a options=("$@")

  echo -e "${BLUE}${prompt}${NC}"
  for i in "${!options[@]}"; do
    echo "$((i + 1)). ${options[$i]}"
  done

  local idx
  while true; do
    read -rp "Choice (number): " idx
    if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le "${#options[@]}" ]; then
      echo "${options[$((idx - 1))]}"
      return
    fi
    warn "Invalid choice, try again."
  done
}

# ── 4. Run disko ───────────────────────────────────────────────────
run_disko() {
  local disko_ref="$1"

  info "Executing disko..."
  nix --experimental-features "nix-command flakes" \
    run github:nix-community/disko/latest -- \
    --mode destroy,format,mount "$disko_ref"
}

# ── 5. Btrfs post-processing ───────────────────────────────────────
btrfs_post() {
  info "Setting root-blank subvolume as read-only..."
  mkdir -p /tmp/btrfs_mnt
  mount -o subvol=/ /dev/mapper/enc /tmp/btrfs_mnt 2>/dev/null || {
    warn "Could not mount btrfs root — root-blank not set read-only. You can do this manually later."
    return
  }
  btrfs property set /tmp/btrfs_mnt/root-blank ro true
  umount /tmp/btrfs_mnt
  success "root-blank set read-only."
}

# ── 6. Copy flake to persist ───────────────────────────────────────
copy_flake() {
  local dest="/mnt/persist/system/etc/nixos/zinx"
  info "Copying flake to ${dest}..."
  mkdir -p "$dest"
  rsync -a --exclude='.git' --exclude='result' --exclude='tmp' "$FLAKE_ROOT/" "$dest/"
  success "Flake copied."
}

# ── Main ───────────────────────────────────────────────────────────
main() {
  check_deps

  cd "$FLAKE_ROOT"

  discover_hosts
  SELECTED_HOST=$(select_option "Select target host:" "${HOSTS[@]}")

  discover_layouts
  SELECTED_LAYOUT=$(select_option "Select disk layout:" "${LAYOUTS[@]}")

  # If the layout is a flake output (e.g. "hostMain"), reference it as .#hostMain
  # If it's a file path, use that directly
  if [[ "$SELECTED_LAYOUT" == /* ]]; then
    DISKO_REF="$SELECTED_LAYOUT"
  else
    DISKO_REF=".#${SELECTED_LAYOUT}"
  fi

  # Final confirmation
  echo -e "${RED}─── CRITICAL: FINAL CONFIRMATION ───${NC}"
  echo -e "Host:   ${YELLOW}$SELECTED_HOST${NC}"
  echo -e "Layout: ${YELLOW}$(basename "$SELECTED_LAYOUT")${NC}"
  echo -e "Action: ${RED}WIPE DISK AND CREATE PARTITIONS${NC}"
  read -rp "Type 'YES' to proceed: " final_confirm
  [[ "$final_confirm" != "YES" ]] && error "Aborted."

  run_disko "$DISKO_REF"
  btrfs_post
  copy_flake

  success "Disk preparation complete. Run: just install"
}

main "$@"
