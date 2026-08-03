# VM Testing (`sandbox` host, plain build-vm)

The dedicated `sandbox` host is a **clean, disposable experiment box** — no disko, no LUKS,
no impermanence. Its purpose is fast iteration on declarative desktop experiments
(hyprland, niri, lxqt, home-manager/hjem variants, etc.):
get a clean OS, turn the experimental module on, see if it evals + boots. Nothing it does
can touch `uriel`'s disk stack.

## Setup (`nixos/hosts/sandbox/configuration.nix`)

- Same module set as uriel minus the disk stack, printer, and extras:
  `base/general/desktop/nix/keyd`. No `inputs.disko`, no `impermanence`, no printer.
- `hardware-configuration.nix` = `modulesPath + "/profiles/qemu-guest.nix"` + virtio
  kernel modules. No real hardware.
- Plain disk: `virtualisation.memorySize = 4096`, `virtualisation.diskSize = 40960`
  (MB). The VM tooling creates and formats the disk itself — no disko involved.
- `modulesPath + "/virtualisation/qemu-vm.nix"` is imported directly so the
  `virtualisation.*` options are declared at base level and `system.build.vm` is a
  buildable flake output (see `KB/birdee-inspiration.md` note on VM approach).

## Run

```bash
nixos-rebuild build-vm --flake .#sandbox   # builds config + VM wrapper
./result/bin/run-vm-sandbox                # boots a QEMU window (LXQt via desktop module)
```

`qemu-vm.nix` is imported directly into the host, so `system.build.vm` is a normal
flake output — no `nixos-rebuild` magic required:
```bash
nix build .#nixosConfigurations.sandbox.config.system.build.vm   # → result, run ./result/bin/run-vm-sandbox
```

State is ephemeral per run — a broken experiment is discarded by closing the VM and
rebuilding. For scripted runs, uncomment in the host config:
```nix
virtualisation.graphics = false;
boot.kernelParams = [ "console=ttyS0,115200n8" ];
```

## Gotcha: niri blackscreens in the VM (needs GL)

niri hard-requires OpenGL (Smithay wants `EGL_EXT_device_drm`). The default QEMU
display is **std VGA — a plain framebuffer with no GL**, so niri starts and the
screen goes black after SDDM login (qylock SDDM theme + the quickshell lockscreen
still work — they only need software rendering). The sandbox host fixes it by
passing a **virgl (GL) virtio GPU** — nixpkgs' qemu is built with `virglrenderer`:

```nix
virtualisation.qemu.options = [
  "-device virtio-vga-gl"
  "-display gtk,gl=on"
];
```

(For reference: upstream niri issue #2567 / smithay #1415 — "No supported plane
buffer format found" / "Missing required EGL extensions: EGL_EXT_device_drm".
Hyprland/sway work without GL because they're not GL-bound the same way.)

## Gotcha: SDDM greeter shows the stock X cursor

SDDM runs its own X cursor before the session; with no cursor theme installed it
shows the default "X". `desktop.nix` installs `capitaine-cursors` and sets
`services.displayManager.sddm.settings.Theme.CursorTheme`/`CursorSize`; niri gets
its own `cursor { xcursor-theme "capitaine-cursors" }` block in the wrapper.

## Gotcha: VM login password

`initialHashedPassword` is **one-shot, applied only at account creation**
(`update-users-groups.pl`: existing users take the `if (defined $existing)` branch and
their `/etc/shadow` entry is never touched; only new accounts get the config hash).
On uriel, `kdj` predates the hash, so the config's hash was dead code there — the VM,
with a fresh disk, applies it, hence the "unknown" password. Root cause: a shared module
(`general.nix`) carried a machine-specific secret. Now `general.nix` sets no password;
each host sets its own. The vm host pins a known dev password (`vm`):
```nix
users.users.${config.preferences.user.name}.initialHashedPassword = "…hash of `vm`…";
```

## Why plain build-vm (vs the old vmWithDisko)

- **Fast**: no LUKS format step, no `disko.imageBuilder` workaround, no image build.
- **Safe**: cannot mangle `uriel`'s disko/config; the vm host is fully self-contained.
- The trade-off is that the VM does NOT test the disk/rollback stack — that was already
  validated and documented below (archived).

---

# ARCHIVED: full disk-stack testing via `vmWithDisko`

Removed 2026-08-02 when `uriel` and `vm` were separated (uriel got the block deleted;
vm became a plain build-vm box). Keep this knowledge if the disk stack ever needs
VM-testing again.

## Goal (archived)

Boot the **entire real config** (disko layout + LUKS + impermanence) in a QEMU VM to
validate the disk stack end-to-end. Plain `build-vm` cannot do this — it attaches an
empty/impermanent virtual disk and never formats it per `disko.nix`.

## How it worked

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
   - runs the normal `run-<host>-vm` script against that overlay.

So the image is formatted once, then the overlay is booted — state from a failed boot
can be discarded by rerunning the script.

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

### The workaround

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

## Verified boot markers (when it was working, 2026-08-02)

Headless boot, capture serial output, then look for these:

```
Finished Cryptography Setup for enc.        # LUKS unlocked via keyfile, no prompt
Finished Rollback BTRFS root subvolume to a pristine state.   # impermanence nuke
Mounted /sysroot/persist                     # + /home, /nix, /var/log
Reached target Graphical Interface.           # full boot
<host> login:                                # login prompt on ttyS0
```

## Archived commands

```bash
nix run -L .#nixosConfigurations.<host>.config.system.build.vmWithDisko
nix build -L --no-link --print-out-paths '.#nixosConfigurations.<host>.config.system.build.vmWithDisko'
timeout 180 <store>/disko-vm/bin/disko-vm > boot.log 2>&1
```

Note: building `.config.system.build.diskoImages` directly (without the variant) uses
the base config and does NOT get the `imageBuilder.pkgs` override — only the
`vmWithDisko` path is fixed.
