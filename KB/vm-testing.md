# VM Testing (`vmWithDisko`)

Goal: boot the **entire real config** (disko layout + LUKS + impermanence) in a QEMU VM
to validate the disk stack end-to-end. Plain `build-vm` cannot do this — it attaches an
empty/impermanent virtual disk and never formats it per `disko.nix`.

## How it works

`vmWithDisko` comes from disko's `lib/interactive-vm.nix` and is exposed by the disko
NixOS module as `virtualisation.vmVariantWithDisko` (a `mkOption` whose value is any
NixOS module config applied **only** to the VM build).

Pipeline (verified in disko source at pinned rev):

1. `system.build.diskoImages` — disko formats a fresh virtual disk inside a build VM
   (`vmTools.runInLinuxVM`), running the real `destroyFormatMount` script against a
   qcow2 created with `qemu-img create ... ${disk.imageSize}`. **`imageSize` is required**
   on every `disko.devices.disk.*`.
2. `disko.testMode = true` is force-set by both `make-disk-image.nix` and
   `interactive-vm.nix`, so the LUKS format uses the hardcoded test passphrase (see `disko.md`).
3. `system.build.vmWithDisko` = a `writeDashBin` script that:
   - `qemu-img create -b <store>/main.qcow2 -F qcow2 "$tmp"/main.qcow2` (copy-on-write overlay)
   - runs the normal `run-uriel-vm` script against that overlay.

So the image is formatted once, then the overlay is booted — state from a failed boot
can be discarded by rerunning the script.

## Current config (`nixos/hosts/uriel/configuration.nix:52`)

```nix
virtualisation.vmVariantWithDisko = {
  disko.memSize = 4096;                       # drives build-VM RAM and interactive VM
  virtualisation.fileSystems."/persist".neededForBoot = true;  # + /home + /var/log
  boot.initrd.secrets."/tmp/secret.key" = "${pkgs.writeText "secret.key" "disko"}";
  boot.initrd.luks.devices.enc.keyFile = "/tmp/secret.key";
  disko.imageBuilder.pkgs = pkgs.extend (final: prev: {
    vmTools = prev.vmTools.override (args: args // { kernelImage = "bzImage"; });
  });
  virtualisation.graphics = false;            # headless: serial on stdout
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
};
```

## The vmTools kernel error (the big one)

### Error

```
vmTools: the `kernel` argument (kernel-modules) has no
`target` attribute, so the kernel image filename cannot be determined.
```

### Root cause (verified at nixpkgs `567a49d`)

nixpkgs commit `68d32ed` ("vmTools: fix `img` collision with pkgs.img, add `kernelModules`
arg", PR ~#423933) split the boot image and module tree apart:

- old: `vmTools` took one `kernel` arg, and `kernel.target` gave the boot image filename
- new: `kernelImage` (defaults to `kernel.target`) names the boot image; a separate
  `kernelModules` arg carries the module tree for the initrd
- if `kernel` lacks `.target`, it now **throws** instead of silently defaulting

disko's `lib/make-disk-image.nix` still does `kernel = pkgs.aggregateModules([...])`.
`aggregateModules` is a `buildEnv`, so its output **keeps** `$out/bzImage` but drops the
`.target` passthru — hence the throw.

### Why "bump disko" is the wrong advice

- The disko-side fix (PR #1116, for the *older* `kernel-modules-shrunk` "no modules
  provided" bug #1114) is **already in the pinned rev** — `make-disk-image.nix:48` has
  `++ lib.optional (cfg.kernelPackages.kernel ? modules) cfg.kernelPackages.kernel.modules`.
- The fix for THIS error is PR #1170, still **unmerged**, and our pin is disko master
  (verified via `git ls-remote`). Bumping is a no-op.
- `disko.imageBuilder.kernelPackages` does NOT help — it only swaps which kernel is
  aggregated, every post-split kernel still goes through the same broken `aggregateModules`.

### The working workaround (applied)

Override `disko.imageBuilder.pkgs` so the image builder's `vmTools` gets an explicit
`kernelImage`. This is the exact mitigation the nixpkgs error message itself suggests,
and it keeps the SAME nixpkgs (no 26.05 downgrade, no kernel-version mismatch):

```nix
disko.imageBuilder.pkgs = pkgs.extend (final: prev: {
  vmTools = prev.vmTools.override (args: args // { kernelImage = "bzImage"; });
});
```

Why `bzImage` works: `aggregateModules` is a `buildEnv` over `[kernel, kernel.modules]`,
so the merged output contains the kernel image at `$out/bzImage` (x86_64). Remove this
block once disko PR #1170 lands.

## Verified boot markers

Headless boot, capture serial output, then look for these (all confirmed 2026-08-02):

```
Finished Cryptography Setup for enc.        # LUKS unlocked via keyfile, no prompt
Finished Rollback BTRFS root subvolume to a pristine state.   # impermanence nuke
Mounted /sysroot/persist                     # + /home, /nix, /var/log
Reached target Graphical Interface.           # full boot
uriel login:                                 # login prompt on ttyS0
```

## Headless vs GUI

| Setting | Effect |
| --- | --- |
| `virtualisation.graphics = false` | `-nographic`; serial `ttyS0` on stdout — log/script friendly |
| `boot.kernelParams = ["console=ttyS0,115200n8"]` | kernel prints boot messages to serial |
| drop both | normal QEMU window (interactive Plasma poking) |

Headless is the default in this config for scripted verification. If the LUKS keyfile
ever fails, the password prompt appears on ttyS0 (type `disko`).

## Commands

```bash
nix run -L .#nixosConfigurations.uriel.config.system.build.vmWithDisko   # build + boot
nix build -L --no-link --print-out-paths '.#nixosConfigurations.uriel.config.system.build.vmWithDisko'
timeout 180 <store>/disko-vm/bin/disko-vm > boot.log 2>&1                # capture boot
```

Note: building `.config.system.build.diskoImages` directly (without the variant) uses
the base config and does NOT get the `imageBuilder.pkgs` override — only the
`vmWithDisko` path is fixed.
