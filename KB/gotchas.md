# Gotchas & pitfalls

Non-obvious failures encountered in this repo, with the fix that worked.

## 1. `boot.initrd.secrets` values must be unquoted store paths

**Error:** `Failed assertions: boot.initrd.secrets values must be unquoted paths...`

**Cause:** assertion in `stage-1.nix:749` requires each value to be `builtins.isPath`
or a string with `storeDir` prefix. A raw `pkgs.writeText ...` (which is a derivation
**set**) is rejected.

**Fix:** coerce to a store-path string:
```nix
boot.initrd.secrets."/tmp/secret.key" = "${pkgs.writeText "secret.key" "disko"}";
```

## 2. `vmTools: the kernel argument ... has no target attribute`

Full analysis in `vm-testing.md`. tl;dr nixpkgs 26.11 split `kernel`/`kernelModules`/
`kernelImage`; disko's `aggregateModules` wrapper loses `.target`. Fix is the
`disko.imageBuilder.pkgs` + `kernelImage = "bzImage"` override. **Do not** waste time
bumping disko — the pin is already master and the fix PR (#1170) is unmerged.

## 3. Build artifacts get staged by `git add -A`

`result` (symlink to a nix store path) and `*.qcow2` (VM disk images) end up in the git
index and — worse — inside the flake source (fileset uses git-tracked files). `.gitignore`
now has `result` and `*.qcow2`. If they reappear: `git rm -f <file>` then remove from disk.

## 4. New/renamed `.nix` files must be git-staged to be seen by the flake

The flake source = git-tracked files (via `lib.fileset`). A new file that isn't `git add`-ed
is invisible to eval; a rename done with plain `mv` leaves the old module alive. Use
`git add`/`git mv`. (Also the reason the `_` toggle must use `git mv` — see `module-toggle.md`.)

## 5. Swap `fstab` duplicate warning (benign)

Boot log shows:
```
systemd-fstab-generator: Failed to create unit file '...swap.swap', as it already exists.
Duplicate entry in '/etc/fstab'?
```
Cause: `swap` partition with `resumeDevice = true` in disko emits both an fstab entry and
a swapDevices unit. systemd skips the duplicate; boot is unaffected. Leave it.

## 6. `nix` needs experimental features here

The system `nix` defaults may not enable flakes. Prefix commands:
```bash
nix --extra-experimental-features 'nix-command flakes' <cmd>
```

## 7. Direct `diskoImages` build ignores `imageBuilder.pkgs`

`nix build .#nixosConfigurations.uriel.config.system.build.diskoImages` uses the BASE
config — it does NOT see the `vmVariantWithDisko` override and still hits the vmTools
error. Only the `vmWithDisko` path carries the fix. (Documented in `vm-testing.md`.)

## 8. Extras currently OFF

`nixos/features/_extras.nix` means nvidia/vicinae/cachix are skipped in evals.
Printer is imported directly by `uriel`, outside extras. When debugging nvidia/boot modules, remember which mode you're in —
grep `boot.initrd.kernelModules` output changes drastically between modes.

## 9. kitty 0.48.2 on a stale nixpkgs pin isn't cached → source build + flaky checkPhase

`nixpkgs` lock on an *older* `nixos-unstable` rev means kitty 0.48.2 is neither on
cache.nixos.org nor `nixpkgs` sub-cache, so it compiles from scratch (5+ min). Worse, its
checkPhase runs the flaky `test_fish_integration` PTY suite (nixpkgs#4759), which fails
under the build sandbox.

- **`doCheck = false` is a NOOP for kitty** — this package's `checkPhase` isn't gated by
  `doCheck`, so the drv hash is unchanged and the flaky tests still run. Must override
  `checkPhase = "true"` (that *does* change the drv; verified).
- Put the override in the **overlay** (`nixos/base/overlay.nix`), NOT in
  `nixpkgs.config.packageOverrides` — hjem constructs its own `pkgs` and won't see
  `packageOverrides`; it *does* see `nixpkgs.overlays`. (pluie-style: `jujutsu.doCheck=false`
  via overlay in `overlay.nix`, wired by `nixpkgs.overlays`.)
- To get a *cached* kitty instead: `nix flake update nixpkgs` (latest unstable tip is
  always hydrated). `--only-fully-cached` is **not** a real Nix flag.

## 10. Dual-input `nixpkgs` + `nixpkgs-unstable` (SAVED, user likes it — not yet wired)

Idea (adapted from vimjoyer-style / cache-tracked setups): keep *two* nixpkgs inputs so a
`nixpkgs-unstable`-input pulls **cached-latest** binaries while the main `nixpkgs` stays
pinned/stale for everything else.

- `flake.nix` adds a second input that tracks the live channel (so its tip is always
  hydrated on the cache):
  ```nix
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  ```
- Overlay overrides the flaky/cache-missing package from the *unstable* set:
  ```nix
  # nixos/base/overlay.nix
  flake.overlays.default =
    final: prev:
    (prev.lib.optionalAttrs (self.packages ? ${prev.stdenv.hostPlatform.system})
      self.packages.${prev.stdenv.hostPlatform.system})
    // {
      kitty = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.kitty;
    };
  ```
  Handing the whole `kitty` over (not just a `checkPhase` patch) means its *closure* comes
  from the cached-unstable tip → no compile at all, and no test-run. The main `nixpkgs` pin
  keeps everything else deterministic.
- Trade-off: kitty's closure is theirs non-`nixpkgs` in the rest of the system (a handful of
  cached deps; still mostly shared). Re-evaluate when the main pin eventually catches up past
  that rev and kitty lands in the normal cache.
- This session: dual-input was built, tried (incl. an nixpkgs-stable #nixpkgs-variant), then
  meant due to mid-flight reorg. **User explicitly likes the approach — do it.**

## 11. `nix flake update --only-fully-cached` doesn't exist

There is no such flag in Nix 2.34.8 → `unrecognised flag`. The *latest* unstable tip is the
one guaranteed hydrated, so plain `nix flake update nixpkgs` is the de-facto "cached-latest".
