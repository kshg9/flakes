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
Printer is imported directly by `uriel`, outside extras. When debugging nvidia/boot modules, remember which mode you're in — grep
`boot.initrd.kernelModules` output changes drastically between modes.
