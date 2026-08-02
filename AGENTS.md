# AGENTS.md — working notes for this repository

This file governs how I (the coding agent) work in `/home/kdj/flakes`. The user
experiments by pointing me at **other people's NixOS configs** and asking me to adapt
cool ideas from them. Read this before doing anything.

## Repository shape (read these first)

- `KB/*.md` — the knowledge base. It documents every hard-won lesson in this repo.
  **When I learn something new, I record it there.** Before starting a task, skim the
  relevant KB file.
- `flake.nix` — flake-parts with a custom `importTree`:
  - every `.nix` file in the repo (recursively) is a flake-parts module automatically
  - files starting with `_` are EXCLUDED from the flake (the toggle convention)
- `nixos/hosts/uriel/` — the single host: `configuration.nix`, `disko.nix`,
  `hardware-configuration.nix`
- `nixos/features/` — feature modules (`desktop`, `nix`, `impermanence`, `keyd`, ...).
  `_extras.nix` is the disabled extras bundle (nvidia/printer/vicinae/cachix).
- `nixos/base/`, `nixos/extra/` — base system + wrappers around external modules
- `wrappedPrograms/` — `flake.wrappers.*` built with `nix-wrapper-modules`
- `scripts/` — `rebuild.sh`, `disko.sh`, `install.sh`, `check.sh`
- `~/reference/` — **reference configs to steal from**: `nixconf` (vimjoyer), plus
  `refer1`, `refer2`, `dendriticWillowispll`

## Rules of engagement

1. **Read other configs, adapt ideas** — when the user says "look at X's config", browse
   it, extract the *idea*, then implement it in this repo's own style (this repo's module
   layout, `selfpkgs` pattern, `_`-toggle convention). Don't copy wholesale.
2. **Always respect the `_`-toggle convention** — heavy/optional things go behind a
   toggle-able module (see `KB/module-toggle.md`).
3. **Fileset trap** — new or renamed `.nix` files are INVISIBLE to the flake until
   `git add`/`git mv`-ed (flake source = git-tracked files). Always stage new files.
4. **Gitignore allowlist trap** — `.gitignore` is an allowlist (ignore-all + `!`-rules).
   Any SOURCE file type not allowlisted is invisible to the flake. When adapting a
   config that brings a new source extension (e.g. `.lua`, `.qml`, `.json`), ADD the
   extension to `.gitignore` too, or it silently won't evaluate.
5. **Do not commit unless explicitly asked.** Staging (`git add -A`) is fine and
   expected — it's how files become visible to the flake.
6. **Verify with eval, then build.** Fast gate: `nix eval .#...toplevel.drvPath`.
   Slow gate: actual `nix build`.
7. **Never propose "bump the flake input" without checking** — verify the pin is stale
   first (`git ls-remote <url> HEAD` vs the lock). Our disko pin IS master.

## Commands

```bash
# eval gate (fast)
nix --extra-experimental-features 'nix-command flakes' eval '.#nixosConfigurations.uriel.config.system.build.toplevel.drvPath'

# build
nix --extra-experimental-features 'nix-command flakes' build -L '.#nixosConfigurations.uriel.config.system.build.toplevel'

# VM (plain build-vm experiment box, no disk stack)
nixos-rebuild build-vm --flake '.#sandbox' && ./result/bin/run-vm-sandbox

# installer ISO (Calamares, embeds flake source) — see KB/installer-iso.md
scripts/build-iso.sh

# toggle extras OFF/ON
git mv nixos/features/extras.nix nixos/features/_extras.nix   # OFF
git mv nixos/features/_extras.nix nixos/features/extras.nix   # ON

# stage new files so the flake sees them
git add -A
```

## Current state (verified 2026-08-02)

- nixpkgs `nixos-unstable` rev `567a49d`; disko `ff8702b4` (master); 26.11 era
- host: real machine `uriel` (disko + impermanence + extras toggle OFF)
- test machine: `sandbox` — clean build-vm experiment box (no disko/LUKS/impermanence),
  for hyprland/niri/kde/hjem experiments (see `KB/vm-testing.md`)
- installer: `installer` — minimal graphical installer ISO (no Calamares, no DE; boots into a
  fullscreen kitty+tmux session via the vendored `packages/maximizer/`) that embeds this
  flake's source (`urielOS` alias = disko + nixos-install; see `KB/installer-iso.md`)
- build artifacts `result`/`*.qcow2` are gitignored — don't stage them

## When I learn something new

Update the relevant `KB/*.md` file (or add one) and keep this AGENTS.md's "current
state" section accurate. The KB is my memory for future sessions.
