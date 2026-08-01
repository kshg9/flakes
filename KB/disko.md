# disko specifics

Verified against disko source at pinned rev `ff8702b4` (store path
`/nix/store/w2c23ykc12mswlg8hrrjzb5gv9gvkzwq-source`).

## Test-mode LUKS password

When `IN_DISKO_TEST=1` is set, `lib/types/luks.nix` (`askPassword`) uses:

```sh
export password=disko
```

`IN_DISKO_TEST=1` is exported automatically whenever `disko.testMode = true`, and
`testMode` is force-set by **both** `make-disk-image.nix`'s `systemToInstall` and
`interactive-vm.nix`. So during `vmWithDisko` image creation the `enc` LUKS device
(deduplicate: `settings.askPassword` defaults true — no `passwordFile`/`keyFile` set)
formats silently with passphrase `disko`, no prompt.

You can also set `IN_DISKO_TEST=1` by hand to script fully non-interactive
`nix run github:nix-community/disko -- --mode destroy,format,mount`.

## imageSize is mandatory

`lib/make-disk-image.nix` runs `qemu-img create ... ${disk.imageSize}` per disk. Missing
`imageSize` → eval error. Current value on `disk.main`: `"50G"`. It is only used by the
image builder — the real machine's disko run never touches it (harmless).

## Post-boot unlock (separate mechanism)

The keyfile pair in `vmVariantWithDisko` is **not** the format-time password; it's the
standard `boot.initrd.luks` mechanism for the *subsequent* boot:

```nix
boot.initrd.secrets."/tmp/secret.key" = "${pkgs.writeText "secret.key" "disko"}";
boot.initrd.luks.devices.enc.keyFile = "/tmp/secret.key";
```

- `boot.initrd.secrets` values must be **unquoted store paths** (an assertion in
  `stage-1.nix:749` rejects derivations and non-store strings — see `gotchas.md`).
- Works because disko's test passphrase `disko` matches the keyfile content.

## imageBuilder options (`module.nix`)

| Option | Default | Purpose |
| --- | --- | --- |
| `disko.imageBuilder.pkgs` | `pkgs` | whole pkgs set for the image builder (use to patch `vmTools`) |
| `disko.imageBuilder.kernelPackages` | `config.boot.kernelPackages` | swap kernel for cross/foreign builds — does NOT fix the vmTools error |
| `disko.imageBuilder.copyNixStore` | `true` | false in the VM path (interactive-vm sets it) |
| `disko.imageBuilder.extraConfig` | `{}` | extra module config for the disk-image *build* system |
| `disko.tests.extraConfig` | `{}` | extra config composed into `vmVariantWithDisko` AND `installTest` |
| `disko.imageBuilder.qemu` | `null` | qemu emulator string (binfmt cross-building) |

## installTest / nixos-anywhere — vmTools-free alternatives

Neither goes through `make-disk-image.nix`/`vmTools`, so both are immune to the
`kernel.target` bug class:

- `config.system.build.installTest` — via `diskoLib.testLib.makeDiskoTest` →
  standard nixpkgs `make-test-python.nix` driver. Deterministic CI pass/fail:
  `nix build -L '.#nixosConfigurations.uriel.config.system.build.installTest'`
- `nixos-anywhere --vm-test` — boots a real kexec installer VM, runs the identical
  disko + nixos-install sequence, feeds LUKS keys:
  `nix run github:nix-community/nixos-anywhere -- --flake .#uriel --vm-test --disk-encryption-keys /tmp/secret.key <(echo -n disko)`

`vmWithDisko` remains the choice for interactive poking at the real config.
