# Impermanence

Uses `nix-community/impermanence` wrapped in a custom `persistence` module
(`nixos/features/impermanence.nix` → `nixos/extra/impermanence.nix`).

## Enabling

```nix
persistence.enable = true;
persistence.nukeRoot.enable = true;   # initrd rollback service (see below)
persistence.user = config.preferences.user.name;  # "kdj"
```

## What is persisted

- `/persist/userdata` — user directories + files (declared in `config.persistence.data.*`)
- `/persist/usercache` — cache dirs/files (`config.persistence.cache.*`)
- `/persist/system` — system dirs/files: `/etc/nixos`, `/var/log`, `/var/lib/{bluetooth,nixos,systemd/coredump}`,
  `/etc/NetworkManager/system-connections`, `/tmp`, plus `/etc/machine-id`, `/etc/lact/config.yaml`,
  `/var/keys/secret_file`
- `/home`, `/var/log`, `/persist` are `neededForBoot = true` subvolumes

## Rollback service (`boot.initrd.systemd.services.rollback`)

Runs in the initrd, `after = systemd-cryptsetup@enc`, `before = sysroot.mount`:

1. mount LUKS volume (`/dev/mapper/enc`) at subvol `/`
2. delete all child subvolumes of `/root`, then delete `/root`
3. `btrfs subvolume snapshot /mnt/root-blank /mnt/root` — restore pristine template
4. umount

Requirements on first install (documented in `disko.nix`):
- `root-blank` must exist and be made read-only:
  ```
  mount /dev/mapper/enc /mnt -o subvol=/
  btrfs property set /mnt/root-blank ro true
  umount /mnt
  ```

## VM interplay

Because rollback and persistence run in the initrd against `/dev/mapper/enc`, the VM
must:

- mount `/persist`, `/home`, `/var/log` with `neededForBoot` — otherwise boot fails
  waiting on mount units (set in `vmVariantWithDisko`)
- unlock LUKS non-interactively via keyfile (`boot.initrd.secrets` + `luks.keyFile`),
  otherwise rollback never runs

Verified in the VM: `Rollback BTRFS root subvolume to a pristine state` finishes, then
all persisted subvolumes mount.

## Passwords under impermanence

`passwd` writes to `/etc/shadow`, which `nukeRoot` wipes every boot — so normal
password changes never survive. Instead:

- the hash lives at `/persist/passwords/<user>` (on the persisted subvol);
- the host sets `users.users.<name>.hashedPasswordFile = "/persist/passwords/<user>"`.
  NixOS reads that file **each activation** (update-users-groups.pl), and since
  `/etc/shadow` is wiped, the account is recreated fresh every boot → the file
  hash is always applied. (`hashedPasswordFile` on its own = no NixOS warning;
  combining it with `initialHashedPassword` triggers the "multiple password
  options" warning.)
- **change the password with `changepass`** (`packages/changepass.nix`, on the
  system via `general.nix`): prompts like `passwd`, writes the new hash to
  `/persist/passwords/<user>` AND applies it to the live `/etc/shadow` via
  `chpasswd -e` (no reboot needed). Run with `sudo`. Supports
  `--root CHROOT_DIR` (used by the installer to seed `/mnt/persist/passwords`).
- **bootstrap**: the `urielOS` installer calls `changepass --root /mnt <user>`
  during install, seeding `/mnt/persist/passwords/<user>`, so a fresh ISO
  install boots with a known login.

## LUKS name

LUKS device is named `enc` (from `disko.nix`). Used in:
- rollback service: `systemd-cryptsetup@enc`, `/dev/mapper/enc`
- VM keyfile: `boot.initrd.luks.devices.enc.keyFile`
- `config.persistence.luksName` (module option)
