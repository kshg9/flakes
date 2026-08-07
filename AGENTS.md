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
- `nixos/features/` — feature modules (`desktop`, `noctalia`, `nix`, `impermanence`,
  `keyd`, ...). `_extras.nix` is the disabled extras bundle (nvidia/vicinae);
  `cachix.nix` binary caches are always-on (imported directly by both hosts).
- `nixos/base/`, `nixos/extra/` — base system + wrappers around external modules
- `nixos/users/` — **per-user hjem profiles**: `base.nix` (account + hjem wiring +
  shared base, keyed on `preferences.user.name`) + per-user add-ons like `kdj.nix`
  (`userKdj` = base + kdj extras). Hosts pick `userKdj`/`userBase` per user.
- `nixos/features/nixtools.nix` — nix tooling/direnv/nh (renamed from `nix.nix`)
- `wrappedPrograms/` — `flake.wrappers.*` built with `nix-wrapper-modules` (no longer includes Kitty)
- `nixos/hosts/uriel/kitty.conf` — standalone kitty config deployed to `~/.config/kitty/` via home-manager (hjem)
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
   config that brings a new source extension (e.g. `.lua`, `.qml`, `.json`, `.toml`), ADD the
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

## Current state (verified 2026-08-03)

- nixpkgs `nixos-unstable` rev `148bab9`; disko `ff8702b4` (master); 26.11 era
- **per-user hjem profiles live in `nixos/users/`** (migrated 2026-08-06):
  - `base.nix` → `userBase`: hjem wiring + NixOS account + shared hjem base
    (packages, session vars), keyed on `config.preferences.user.name`.
  - `kdj.nix` → `userKdj`: kdj extras (`opencode`, `vscode-fhs`), imports `userBase`.
  - uriel imports `userKdj` (kdj); sandbox imports `userBase` (ephemeral `biyoo`)
    + test apps (yazi) merged via `hjem.users.biyoo.packages`.
  - `users.mutableUsers = false` — fully declarative user/group management.
  - The account/packages/`users.users.*` previously in `features/general.nix` moved
    here; `general.nix` now only holds system/admin bits (`changepass`) + persistence.
    The old `nixos/extra/hjem.nix` wiring was folded into `base.nix` (deleted).
  - App packages (firefox/libreoffice/brightnessctl/bibata-cursors/nix-tooling) moved
    out of `environment.systemPackages` into the hjem user profile. `niri`/`kitty`
    stay in `desktop.nix` systemPackages (session-critical).
- **overlay + theme + hjem-ext** (added 2026-08-06):
  - `nixos/base/overlay.nix` → `flake.overlays.default` merges `self.packages`
    into nixpkgs. Wired via `nixpkgs.overlays = [ self.overlays.default ]` in
    `features/general.nix` (uriel+sandbox) and the installer host. Killed the
    `selfpkgs` let-binding in all *host* modules (desktop.nix → `pkgs.niri/kitty`,
    users/* → `pkgs.*`, installer → `pkgs.changepass`).
    **Cycle guard:** the overlay must NOT be applied to the perSystem pkgs that
    build `self.packages` themselves — so `wrappedPrograms/*` internal
    cross-refs (`fish.nix → selfpkgs.starship`, `environment.nix →
    selfpkgs.yazi/qalc`) intentionally STILL use `selfpkgs`.
  - `nixos/base/theme.nix` → `options.flake.ctp` (`{flavor;accent;}` submodule,
    default mocha/mauve) + derived `config.flake.ctpPalette` (base/accent hex).
    Captured in an **outer `let`** before entering `flake.wrappers.*` because the
    inner wrapper `config` shadows flake-parts' `config`. Applied to `kitty.nix`
    (cursor/selection/url/active-border = accent) and `niri.nix` (focus-ring
    active-color).
  - `nixos/hjem-ext.nix` → `flake.nixosModules.hjemExt` (imported once in
    `general.nix`). Sets `hjem.specialArgs` (injects ctpPalette into hjem as
    `ctp`) + a single shared `hjem.extraModules` module declaring
    `ext.programs.<name>` = { enable; settings; configPath } → rendered via
    `pkgs.formats.toml` to `~/.config/<configPath>` with `lib.mkIf` per entry.
    **specialArgs trap:** `config.flake.*` is a flake-parts namespace, NOT visible
    from NixOS modules (hjem-ext, kdj.nix). The resolved palette is injected into
    every `nixosSystem` via `specialArgs.ctp = config.flake.ctpPalette` at the
    host `flake.nixosConfigurations.*` definitions (host configs ARE flake-parts
    modules, so `config.flake` is in scope there). kitty/niri wrappers read
    `config.flake.ctpPalette` directly because they're perSystem modules.
  - **niri config → hjem** (see roadmap): wrapped `niri` deleted; stock
    `pkgs.niri`; config = pluie-style file `nixos/users/files/niri/config.kdl`
    sourced via `xdg.config.files."niri/config.kdl".source` in kdj.nix (needs
    `!*.kdl` gitignore allowlist + git add).
  - **kitty + yazi → hjem** (added 2026-08-06, same as niri): both wrappers
    deleted; stock `pkgs.kitty`/`pkgs.yazi`. Shared dotfiles in base.nix from
    `nixos/users/files/{kitty,yazi}/`: `kitty.conf`, `yazi.toml`, `yazi/init.lua`,
    and the full-border plugin symlinked from `${pkgs.yaziPlugins.full-border}`
    into `yazi/plugins/full-border.yazi`. yazi reads ~/.config/yazi (the wrapper
    used to set YAZI_CONFIG_HOME to a store dir). `environment.nix` now uses
    `pkgs.yazi` (nixpkgs); qalc stays wrapped. Configs were byte-captured from
    the old toKeyValue/toKdl renderers (needs `!*.lua` too). Remaining wrappers:
    `environment`, `fish`, `qalc`, `starship` + plain packages `changepass`,
    `maximizer`, `vicinae`.
- login: **SilentSDDM** (catppuccin-frappe) via `features/lockscreen.nix`
  (`programs.silentSDDM.enable`, flake input `silentSDDM`) — replaces plain breeze
  greeter. qylock removed (no custom lockscreen; `Mod+Shift+Q` lock keybind removed
  from `niri.nix`)
- host: real machine `uriel` (disko + impermanence + printer + extras toggle OFF, cachix always-on)
  - noctalia: stock defaults (no custom settings.toml)
- test machine: `sandbox` — clean build-vm experiment box (no disko/LUKS/impermanence),
  for hyprland/niri/lxqt/hjem experiments (see `KB/vm-testing.md`)
- installer: `installer` — minimal graphical installer ISO (no Calamares, no DE; boots into a
  fullscreen kitty+tmux session via the vendored `packages/maximizer/`) that embeds this
  flake's source (`urielOS` alias = disko + nixos-install; see `KB/installer-iso.md`)
- build artifacts `result`/`*.qcow2` are gitignored — don't stage them

## Roadmap — plan of record (in progress)

> Captured 2026-08-06. Tick items off as they land. The big theme: go **hjem-centric**
> per-user rather than system-wide, so the display/logic is "who is logged in" instead of
> "what Nix module is imported". Reference for hjem wiring: `~/insp/pluieflake` (users/
> + `hjem.extraModules` + `hjem-ext/` program modules) and `~/insp/lunix` (tool modules).

### App sandpack
- [ ] **tldeer** — Rust rewrite of `tldr` (user's pick, distinct from tealdeer). NOT in nixpkgs
  as `tldeer`; source via flake input/overlay. NOTE: wrapper-modules only ships a `tealdeer`
  wrapper, so tldeer gets its own `wrappedPrograms/tldeer.nix` (or plain package)
- [ ] **obsidian / anki / vesktop** — add to packages (vesktop config via hjem when per-user)
- [ ] **tuxedo** — `tuxedo-control-center` (+ tuxedo-rs kernel if needed); see `lunix/modules/cli/tools/tuxedo.nix`
- [ ] **vscode → vscodium** — swap in user packages (currently `vscode-fhs` in `nixos/features/general.nix`)
- [ ] **firefox + chromium** — firefox already `programs.firefox`; add `chromium`
- [ ] **git wrapper module** — `wrappedPrograms/git.nix` via `wlib.wrapperModules.git`
- [ ] **jujutsu wrapper module** — `wrappedPrograms/jujutsu.nix` via `wlib.wrapperModules.jujutsu`
- [ ] **lazygit** — NO wrapper module exists in wrapper-modules; configure via hjem `config.files` (config.toml)
- [ ] **rclone / sops** — add to packages (later; sops for secrets)

### Boot
- [ ]  **plymouth (LUKS decrypt)**: add flake input `mac-style-plymouth = { url = "github:SergioRibera/s4rchiso-plymouth-theme"; inputs.nixpkgs.follows = "nixpkgs"; }` (themes the `/dev/mapper/enc` unlock prompt); enable `boot.plymouth.enable` in `uriel` (runs before LUKS passphrase) and wire theme
- [x]  **lanzaboote (Secure Boot)**: flake input `lanzaboote` (`github:nix-community/lanzaboote`) + `inputs.lanzaboote.nixosModules.lanzaboote` + `boot.lanzaboote.enable`. Implemented as toggle-able feature `nixos/features/lanzaboote.nix` (`flake.nixosModules.lanzaboote`), imported by uriel via `lib.optional (self ? nixosModules.lanzaboote)` — rename `lanzaboote.nix`→`_lanzaboote.nix` to fall back to systemd-boot. Forces `boot.loader.systemd-boot.enable = false`; `pkiBundle = "/etc/secureboot"` (persisted via `persistence.directories` → `/persist/system`); `autoGenerateKeys`+`autoEnrollKeys` on (generates keys first boot, exports .auth to ESP, next reboot in Setup Mode enrolls them). Need: put firmware into Setup Mode once, then reboot; verify with `sbctl status`/`bootctl status`. **Verify UEFI + LUKS/plymouth interplay before enabling.**

### Helix
- [x]  custom helix config: transparent background + **kanagawa** theme, via hjem `config.files`. Minimal: `files/helix/config.toml` = `theme = "kanagawa-transparent"` only; `files/helix/kanagawa-transparent.toml` = `inherits = "kanagawa"` + `"ui.xxx" = {}` to unset the opaque bg scopes (helix CANNOT inline a theme in config.toml — `duplicate key theme` TOML error, verified against the 25.07 binary). Sourced in kdj.nix.
- [x]  pick ONE path (wrapper module vs hjem) for helix dotfile management — prefer wrapper where a module exists, hjem otherwise → **chose hjem** (stock `pkgs.helix` in kdj packages + dotfiles)

### Noctalia / niri → hjem (the pivot)
- [x] **Preserve noctalia `config.toml`** — noctalia's own hjem module (`inputs.noctalia.hjemModules.default`, imported via `hjem-ext`) exposes `programs.noctalia`, which validates and writes `~/.config/noctalia/config.toml` per-user. kdj.nix sets `settings` (dark muted `Catppuccin` + `settings_show_advanced`). Survives rebuilds declaratively instead of being runtime-touched.
- [x] **Migrate niri config → hjem** (was baked into `wrappedPrograms/niri.nix` + `NIRI_CONFIG` unit env → **deleted**). niri is now stock nixpkgs (`pkgs.niri`) reading `~/.config/niri/config.kdl`, which hjem writes from `nixos/users/files/niri/config.kdl` (byte-captured from the old wrapper's toKdl renderer, `xdg.config.files."niri/config.kdl".source = ./…` — pluie-style). **needs `!*.kdl` in `.gitignore` + `git add` for flake visibility**.
- [ ] overall: source app dotfiles from `.config/` through hjem; make the repo hjem-centric

### User-centric (laziness + testing)
- [x]  **uriel users**: `kdj` (full access, hjem `userKdj`) + `yjh` (guest). **sandbox**: single ephemeral user `biyoo` (build-vm; uses `userBase`).
- [x]  per-user hjem profiles in `nixos/users/{base,kdj}.nix`, wired into uriel (`userKdj`) and sandbox (`userBase`/biyoo)
- [x]  migration from single `preferences.user.name` → a per-user mapping (e.g. host → [users]), so host = f(users) and hjem assets are pulled per-user (done: `preferences.user.name` option deleted; hosts already pick `userKdj`/`userBase`)
- [ ]  real env users pull what they need; sandbox user pulls only what's under test (lazily evaluated = easy to juggle)
- [x]  retire `config.base.user.nix` `preferences.user.name` — option deleted; `self.userBase = (name: ...)` factory in `users/base.nix` takes its place

### Guest user `yjh` (restricted, self-cleaning)
- [ ]  `users.users.yjh`: `isNormalUser`, NO `wheel` (no sudo; root has no password), only `lp` group if printing allowed
- [ ]  restrict apps: dev tooling (`helix`, `vscodium`, `opencode`…) already moved into kdj's hjem profile; `general.nix` systemPackages now only `changepass`. REMAINING: yjh's hjem profile carries only allowed apps + no `nix` (can't self-install) — verify `nix` isn't in guest's closure
- [ ]  weekly wipe: `systemd.timer` (`OnCalendar=weekly`, `Persistent=true`) → `loginctl terminate-user yjh`, `rsync --delete` pristine template back to `/home/yjh`, fix ownership; home is also already unpersisted under impermanence (wiped on reboot)
- [ ]  sandbox `biyoo` is ephemeral/dev-only — the same wipe/timer machinery is NOT for it

## When I learn something new

Update the relevant `KB/*.md` file (or add one) and keep this AGENTS.md's "current
state" section accurate. The KB is my memory for future sessions.
