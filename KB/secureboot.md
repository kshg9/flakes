# Secure Boot (lanzaboote)

UEFI Secure Boot via `nix-community/lanzaboote`. Replaces systemd-boot's boot
signing with a proper keychain: kernels/initrds are signed UKIs.

## Wiring

- `flake.nix` input `lanzaboote` (github:nix-community/lanzaboote).
- `nixos/features/lanzaboote.nix` → `flake.nixosModules.lanzaboote`,
  imported by uriel via `lib.optional (self ? nixosModules.lanzaboote)`.
  Rename `lanzaboote.nix` → `_lanzaboote.nix` to fall back to systemd-boot
  (the host keeps `boot.loader.systemd-boot.enable = true` as the safe default).
- `boot.lanzaboote.pkiBundle = "/etc/secureboot"` — the db/PK/KEK signing key
  bundle. It is **persisted** (`persistence.directories = [ "/etc/secureboot" ]`
  → `/persist/system/etc/secureboot`) because `/etc` is on the nukeRoot subvol
  and would be wiped on every boot.
- `autoGenerateKeys.enable = true` → `generate-sb-keys.service` runs
  `sbctl create-keys` on first boot if `${pkiBundle}/keys` doesn't exist.
- `autoEnrollKeys.enable = true` → `prepare-sb-auto-enroll.service` exports
  PK/KEK/db `.auth` files to the ESP; the **next** reboot enrolls them via
  systemd-boot while the firmware is in Setup Mode. `autoReboot` is left OFF so
  the operator controls that reboot.

## First-time enable (manual steps on the real machine)

1. Rebuild/activate with the feature on (or fresh install). Boot twice: first
   boot generates keys + exports `.auth`; second boot (still Setup Mode)
   enrolls them.
2. If the firmware isn't in Setup Mode yet, put it there:
   - ThinkPad: Security → Secure Boot → Enable → "Reset to Setup Mode".
     **Don't** "Clear All Secure Boot Keys" (drops dbx).
   - Framework: Administer Secure Boot → delete PK/KEK/DB entries one by one
     (**not** "Erase all Secure Boot Settings" — buggy on most models).
3. Verify enrollment: `sbctl status` (user mode), `sbctl verify` (all EFI
   binaries signed), `bootctl status` (Secure Boot: enabled).
4. Manual alternative to autoEnroll: `sudo sbctl enroll-keys --microsoft`
   (add `--firmware-builtin` on Framework for vendor firmware updates).

## Notes / gotchas

- Lanzaboote currently requires systemd-boot as the underlying boot manager;
  it takes over the signing.
- `sbctl` is on the system for debugging (`environment.systemPackages`).
- **Verify UEFI + LUKS/plymouth interplay before enabling on uriel** — boot
  path is LUKS `enc` → btrfs → impermanence rollback, all in a signed initrd.
- Measured boot (`boot.lanzaboote.measuredBoot`) and TPM LUKS enrollment
  (`systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1pX`) are possible
  follow-ups; see haseebmajid.dev's Framework setup write-up.
