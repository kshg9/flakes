# Knowledge Base

Operational knowledge for the `/home/kdj/flakes` NixOS configuration. Verified against
primary sources (nixpkgs/disko at the pinned revisions in `flake.lock`), not hearsay.

Current environment (verified 2026-08-02):

- nixpkgs: `nixos-unstable` rev `567a49d` (2026-06-16) — **26.11 "Zokor" pre-release**
- disko: `ff8702b4` (2026-06-11) — this IS disko master HEAD (checked via `git ls-remote`)
- flake-parts with custom `importTree` (see `module-toggle.md`)

## Index

| File | Topic |
| --- | --- |
| [vm-testing.md](vm-testing.md) | Running the full config in a VM (`vmWithDisko`), the vmTools kernel error and its workaround, verified boot |
| [disko.md](disko.md) | disko specifics: LUKS test password, imageSize, keyfile, image builder options |
| [module-toggle.md](module-toggle.md) | The `_`-prefix toggle convention and how `importTree`/`fileFilter` works |
| [terminal-wrapper.md](terminal-wrapper.md) | The `flake.wrappers.terminal` facade, `binName`, and the `selfpkgs` pattern |
| [impermanence.md](impermanence.md) | Rollback service, LUKS interplay, VM `neededForBoot` requirements |
| [gotchas.md](gotchas.md) | Non-obvious pitfalls and their fixes (assertions, fileset, artifacts) |

## Commands that matter

```bash
# full config eval check (fast)
nix eval .#nixosConfigurations.uriel.config.system.build.toplevel.drvPath

# VM disk image + interactive VM, headless serial on stdout
nix run -L .#nixosConfigurations.uriel.config.system.build.vmWithDisko

# build without launching
nix build -L --no-link --print-out-paths .#nixosConfigurations.uriel.config.system.build.vmWithDisko

# just the raw disk image (base config, no vmVariantWithDisko overrides)
nix build -L .#nixosConfigurations.uriel.config.system.build.diskoImages

# eval a single attribute with a specific input pinned
nix flake metadata        # show resolved revs
git ls-remote https://github.com/nix-community/disko.git HEAD  # is the pin stale?
```

> `git ls-remote ... HEAD` returning the same rev as your lock means you're already on
> latest — do not burn time "bumping" an input that isn't stale.
