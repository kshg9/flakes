# Noctalia desktop shell (niri + noctalia)

Replaced the LXQt/labwc experiment. The desktop is now **niri** (scrollable tiling
compositor) driven by **noctalia v5** (the bar/window-switcher/settings shell). Both
are flake inputs; noctalia is pinned to its `cachix` branch for prebuilt binaries.

## Layout

- `flake.nix` inputs:
  - `noctalia.url = "github:noctalia-dev/noctalia/cachix"` — deliberately does **not**
    follow nixpkgs (a `follows` would change the derivation hash and miss the cache).
  - `niri` is not a separate input — it's wrapped via `wrapper-modules` from nixpkgs.
- `wrappedPrograms/niri.nix` — `flake.wrappers.niri` (was `_niri.nix`, the `_` toggle
  kept it out of the flake; renamed to `niri.nix` to enable it).
- `nixos/features/noctalia.nix` — `self.nixosModules.noctalia`, imports
  `inputs.noctalia.nixosModules.default`, sets `programs.noctalia` with the flake's
  package + `recommendedServices.enable`.
- `nixos/features/desktop.nix` — SDDM + niri session. `services.displayManager.sessionPackages`
  and `systemd.packages` both get `selfpkgs.niri` (the desktop entry + user units come
  from the wrapper).

## How the wrapper feeds niri its config

- `config.settings` in the wrapper (a `nix-wrapper-modules` module) generates
  `niri-config.kdl` (landed in the store as `.../niri-config.kdl`).
- The wrapper sets `env.NIRI_CONFIG = .../niri-config.kdl` and patches the user unit's
  `ExecStart`/`ExecReload` to the wrapped binary — so `NIRI_CONFIG` is in effect even
  though niri is started via `niri-session` → systemd.
- Validation: the wrapper's install phase runs `niri validate` on the generated KDL, so
  a bad setting fails the build instead of at runtime. `nix build .#packages.x86_64-linux.niri`
  is the fast feedback loop.

## Noctalia wiring

- `spawn-at-startup = [ [ "noctalia" ] [ "vicinae" "server" ] ]` in the KDL.
- IPC binds moved off vicinae's keys (vicinae owns `Mod+Space` launcher + `Mod+P`
  clipboard):
  - `Mod+Shift+Space` → `noctalia msg panel-toggle launcher`
  - `Mod+S` → `noctalia msg panel-toggle control-center`
  - `Mod+Comma` → `noctalia msg settings-toggle`
  - `Alt+Tab` → `noctalia msg window-switcher`
- Noctalia's settings window floats via a window-rule
  (`app-id = "^dev\\.noctalia\\.Noctalia$"`, fixed 1080x920, open-floating).
- `debug.honor-xdg-activation-with-invalid-serial` needed for notification actions +
  window activation from noctalia IPC.
- Cache: `noctalia.cachix.org` added in `nixos/features/cachix.nix`
  (key `noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=`).

## Gotchas learned

- `cursor.xcursor-theme` was dropped — noctalia brings its own cursor/theme handling;
  setting one in niri caused a conflict.
- `lib`/`self` args in the wrapper module were removed once
  `self.themeNoHash` (a reference-config leftover) was replaced with a hardcoded color.
- New `.nix` files are invisible to the flake until `git add`ed (fileset trap) — staging
  `nixos/features/noctalia.nix` was required before eval saw `self.nixosModules.noctalia`.
- nixpkgs moved: `nixos-unstable` rev `148bab9` (2026-08-01) now; `nixos-26.11` era.
- xdg-desktop-portal 1.17+ requires `xdg.portal.config` (or `configPackages`), else it
  warns. The right setup for niri mirrors nixpkgs' `programs.niri` module: `config.niri`
  keyed to the session (NOT `config.common.default = "*"`), with **both** the gtk portal
  (default fallback: Access/Notification/FileChooser) **and** the gnome portal
  (screencasting), plus `services.gnome.gnome-keyring` for the Secret portal. niri does
  NOT pull any portal in by itself — it only ships `niri-portals.conf` (in
  `$out/share/xdg-desktop-portal/`).

## Reference configs

- noctalia shell defaults from `~/reference/nixconf` (vimjoyer) + noctalia's own repo;
  window-switcher/settings are `noctalia msg` subcommands, not separate apps.
