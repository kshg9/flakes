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
| [vm-testing.md](vm-testing.md) | The plain build-vm `vm` experiment host; archived vmWithDisko/vmTools lessons |
| [disko.md](disko.md) | disko specifics: LUKS test password, imageSize, keyfile, image builder options |
| [module-toggle.md](module-toggle.md) | The `_`-prefix toggle convention and how `importTree`/`fileFilter` works |
| [terminal-wrapper.md](terminal-wrapper.md) | The `flake.wrappers.terminal` facade, `binName`, and the `selfpkgs` pattern |
| [impermanence.md](impermanence.md) | Rollback service, LUKS interplay, VM `neededForBoot` requirements |
| [gotchas.md](gotchas.md) | Non-obvious pitfalls and their fixes (assertions, fileset, artifacts) |
| [birdee-inspiration.md](birdee-inspiration.md) | Ideas worth stealing from `~/reference/birdeeSystems` (wrapper splat, disko wrapper pkgs, configsPerSystem) |
| [installer-iso.md](installer-iso.md) | Calamares installer ISO (`installer` host), embedded flake source, the `urielOS` one-shot install alias |
| [noctalia.md](noctalia.md) | The niri + noctalia desktop shell: wrapper NIRI_CONFIG flow, IPC binds, cache |
| [qylock.md](qylock.md) | Upstream qylock flake input: star-rail SDDM theme + Quickshell lockscreen, per-desktop themes |

## Commands that matter

```bash
# full config eval check (fast)
nix eval .#nixosConfigurations.uriel.config.system.build.toplevel.drvPath

# experiment VM (plain build-vm, no disk stack) — build + boot
nixos-rebuild build-vm --flake .#sandbox
./result/bin/run-vm-sandbox

# just the raw disk image for the real machine (archived vmWithDisko note:
# building diskoImages directly never got the imageBuilder override)
nix build -L .#nixosConfigurations.uriel.config.system.build.diskoImages

# eval a single attribute with a specific input pinned
nix flake metadata        # show resolved revs
git ls-remote https://github.com/nix-community/disko.git HEAD  # is the pin stale?
```

> `git ls-remote ... HEAD` returning the same rev as your lock means you're already on
> latest — do not burn time "bumping" an input that isn't stale.
