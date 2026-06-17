set shell := ["bash", "-uc"]

disko:
    @echo "=== Partitioning disk ==="

    if [ ! -b /dev/disk/by-id/nvme-SAMSUNG_MZALQ512HBLU-00BL2_S65DNX1T647774 ]; then
        echo "ERROR: disk not found at /dev/disk/by-id/nvme-SAMSUNG_MZALQ512HBLU-00BL2_S65DNX1T647774" >&2
        exit 1
    fi

    nix --extra-experimental-features "flakes nix-command" \
        run github:nix-community/disko -- \
        --mode destroy,format,mount \
        --flake .#hostMain

    @echo "=== Setting root-blank as readonly ==="
    mkdir -p /tmp/btrfs_mnt
    mount -o subvol=/ /dev/mapper/enc /tmp/btrfs_mnt
    btrfs property set /tmp/btrfs_mnt/root-blank ro true
    umount /tmp/btrfs_mnt

    @echo "=== Copying flake to persist ==="
    mkdir -p /mnt/persist/system/etc/nixos
    rsync -a --exclude='.git' ./ /mnt/persist/system/etc/nixos/zinx/

    @echo ""
    @echo "Done. Run: just install"

install:
    @echo "=== Installing NixOS ==="
    nixos-install --flake "/mnt/persist/system/etc/nixos/zinx#main"

rebuild:
    nix flake check
    sudo nixos-rebuild switch --flake "/etc/nixos/zinx#main"
