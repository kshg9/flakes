# KB: hjem — canonical per-user config structure

> Purpose: single reference I (the coding agent) consult when refactoring this
> repo from a system-wide `users.users` / `environment.systemPackages` /
> `environment.sessionVariables` mixing into a **hjem-centric, per-user**
> structure. Written 2026-08-06 by studying `~/insp/pluieflake` and
> `~/insp/lunix`.

## 0. The core idea

NixOS's system-level knobs (`users.users`, `environment.systemPackages`,
`environment.sessionVariables`) apply to the **whole machine**, not a person.
The refactor goal (see AGENTS.md roadmap): make config driven by **"who is
logged in"** (`hjem.users.<name>`) rather than "which Nix module was imported".

hjem lets you declare, per OS user:

- packages installed into their home profile
- dotfiles (`~/.config/...`, arbitrary paths, `~/.profile`, ...)
- session environment variables
- user systemd units / autostart

The NixOS side only handles OS-level concerns (account creation, groups, shell,
password). **Define the user once in NixOS, configure everything else under
`hjem.users.<name>`, both keyed by the same username.**

## 1. Wiring hjem into a host

Already done in this repo — `nixos/extra/hjem.nix`:

```nix
{ inputs, ... }:
{ flake.nixosModules.extra_hjem = { config, ... }: {
    imports = [ inputs.hjem.nixosModules.default ];

    config = {
      hjem = {
        # clobberFiles → our dotfiles REPLACE anything already present
        clobberByDefault = true;

        users."${config.preferences.user.name}" = {
          enable = true;
          directory = "/home/${user}";
          user = "${user}";
        };
      };
    };
  };
}
```

Bundle extra module sets with `hjem.extraModules` if you add them. This repo's
house style deliberately avoids the `hjem-ext`/`hjem-ctp`/`hjem-rum` layers
pluieflake uses — stick to plain hjem core options unless a task says otherwise.

## 2. Mapping the current "random" patterns → hjem

### 2.1 Where a value belongs

| NixOS (system-level)                | hjem (`hjem.users.<name>`)          |
|-------------------------------------|-------------------------------------|
| account: `isNormalUser`, `extraGroups`, `description`, password/hash | stays here — hjem has no account model |
| `shell`                             | stays here (defines the user's shell) |
| user's package list                 | `packages`                          |
| interactive/desktop apps            | `packages`                          |
| session-only env vars               | `environment.sessionVariables`      |
| dotfiles                            | `xdg.config.files` / `files`        |
| root / service / pre-login apps & vars | keep `environment.*` (rare)      |

### 2.2 The big rewrite (from `nixos/features/general.nix`)

**Before:**

```nix
users.users.${config.preferences.user.name} = {
  isNormalUser = true;
  description = "…";
  extraGroups = [ "wheel" "networkmanager" ];
  shell = selfpkgs.environment;
  packages = with pkgs; [ featherpad opencode vscode-fhs ];  # ← move out
};

environment.systemPackages = with pkgs; [
  helix playerctl selfpkgs.changepass                          # ← split
];
```

**After (hjem-centric):**

```nix
# account only — the NixOS side
users.users.${config.preferences.user.name} = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
  shell = selfpkgs.environment;
};

# everything user-scoped under hjem
hjem.users.${config.preferences.user.name} = {
  packages = with pkgs; [ featherpad opencode vscode-fhs helix ];

  environment.sessionVariables = {
    EDITOR = "hx";
  };
};

# system tools (needed by root / before login / sysadmin) stay
environment.systemPackages = [ selfpkgs.changepass ];
```

Rule of thumb for `environment.systemPackages` → hjem split:

- **move to `hjem.users.<name>.packages`**: anything interactive or desktop (editors,
  browsers, GUI apps, CLI tools the user shells out to).
- **keep in `environment.systemPackages`**: tools needed by root, services, the
  installer ISO, or before any user logs in (e.g. `changepass`).

### 2.3 Dotfiles

- Single static file:
  `hjem.users.<name>.xdg.config.files."app/config.toml".source = ./app/config.toml;`
- Generated content (TOML/INI/JSON/KDL): use `pkgs.formats.toml { }.generate`
  and feed to `.source` (see pluieflake `hjem-ext/programs/swayosd.nix`).
- Raw home paths (`.gtkrc-2`, `.ssh/...`): `hjem.users.<name>.files.".ssh/…".source = …;`
- Whole dotfile folder kept as files in the repo: walk it with a `readDir` helper
  and map every file into `xdg.config.files` (lunix's `mkDots` function).

Example:

```nix
hjem.users.${config.preferences.user.name}.xdg.config.files."kitty/kitty.conf" = {
  source = ./uriel/kitty.conf;   # or: text = ''…'';
};
```

### 2.4 Session vs system environment

- `environment.sessionVariables` (or `.variables`) intended only for the user's
  session → `hjem.users.<name>.environment.sessionVariables`.
- Keep `environment.variables`/`sessionVariables` at system level only when the
  var must reach the SDDM greeter, root, or services (e.g. the SDDM cursor).

```nix
# system (still here — greeter needs it before login)
environment.variables = { XCURSOR_THEME = "…"; XCURSOR_SIZE = "32"; };
services.displayManager.sddm.settings.Theme = { CursorTheme = "…"; CursorSize = 32; };

# user-session — moved under hjem
hjem.users.<name>.environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
  LIBVA_DRIVER_NAME = "nvidia";
  GBM_BACKEND = "nvidia-drm";
  __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  NVD_BACKEND = "direct";
};
```

### 2.5 `users.users.<name>.packages` → `hjem.users.<name>.packages`

Stop setting `packages` on the NixOS user for per-user software; declare it under
`hjem.users.<name>.packages`. If some component genuinely needs it on the NixOS
user object, read it back: `users.users.<name>.packages = config.hjem.users.<name>.packages;`
(pluieflake does this as a known hack — prefer the clean end-state of only hjem).

## 3. Reading hjem values back on the NixOS side

Both sides share one module system, so NixOS modules can consume hjem state:

- `config.hjem.users.<name>.packages` — feed back into a Nix user if needed
- `config.hjem.users.<name>.environment.loadEnv` — re-apply the user env in a
  shell init (lunix `modules/cli/fish.nix` uses it in `loginShellInit`)
- `config.hjem.users.<name>.directory` — build paths that must match the real
  home (lunix uses it for ssh signing keys, GTK files, `NH_FILE`, etc.)

This is how lunix keeps one source of truth (e.g. git signing key path defined by
hjem but consumed by `programs.git`).

## 4. Recommended per-user structure for this repo

```
nixos/
  base/user.nix          → preferences.user.name option (keep)
  users/                 → per-user hjem modules (self-contained)
    base.nix             → userBase: imports hjem, clobberByDefault, account,
                           mutableUsers=false, shared hjem packages/vars
    kdj.nix              → userKdj: kdj extras on top of userBase
  hosts/
    uriel/configuration.nix → userKdj (kdj)
    sandbox/configuration.nix → userBase (ephemeral biyoo)
                            + test apps merged into hjem.users.biyoo.packages
```

Each app lives in exactly ONE place: either a `wrappedPrograms/*.nix` module or a
hjem `users/<name>/programs/<app>.nix` file — never both. Prefer the wrapper
module where one exists, hjem otherwise (see AGENTS.md Helix note).

## 5. Guest / restricted user (`yjh`) pattern

- Account: `users.users.yjh = { isNormalUser = true; extraGroups = []; }` —
  NO `wheel`, no `nix` access.
- Apps: everything currently in `environment.systemPackages` that a guest
  shouldn't have moves into kdj's hjem profile, NOT the system. yjh's hjem
  profile carries only allowed apps.
- Home wipe: `systemd.timer` → `loginctl terminate-user yjh` + rsync template
  (home already unpersisted under impermanence).

## 6. Migration checklist (tick off per task)

- [x] `nixos/features/general.nix`: account no longer declared there; `featherpad`,
      `opencode`, `vscode-fhs`, `helix` moved to hjem user profile
- [x] `nixos/features/desktop.nix`: moved interactive apps (`firefox`,
      `wl-clipboard`, `brightnessctl`, `libreoffice`, bibata-cursors) to hjem;
      kept system/desktop-needed bits (`sddm`, `xdg.portal`, fonts, cursor vars,
      and session-critical `niri`/`kitty`)
- [ ] `nixos/features/nvidia.nix`: session vars → hjem (currently disabled extras)
- [x] `nixos/features/nix.nix`: `nixd/statix/nixfmt/...` dev tools → hjem
- [ ] niri config → hjem `config.files` (kill baked-in `NIRI_CONFIG`)
- [ ] noctalia custom `settings.toml` → hjem so it persists rebuilds
- [x] kitty config managed via wrapped kitty module (kept)
- [ ] `herdr` config → hjem as a normal dotfile
- [ ] helix config → hjem `config.files` (kanagawa theme)
- [x] sandbox/uriel hosts pull per-user hjem sets (uriel=userKdj, sandbox=userBase/biyoo)
- [ ] guest `yjh` restricted hjem profile + weekly wipe timer

## 7. Gotchas

- **Don't duplicate packages** across `environment.systemPackages` and
  `hjem.users.<name>.packages` — pick one owner per app.
- **`clobberByDefault = true`** means managed files overwrite pre-existing ones —
  verify before enabling per-host if user has unmanaged files.
- **New `.nix` files are invisible to the flake** until `git add`'d (fileset =
  git-tracked). After creating `users/` modules, run `git add -A` or they silently
  won't evaluate.
- **`_`-prefix toggles**: heavy/optional user modules go behind the toggle
  convention (see `KB/module-toggle.md`).
- Verify with `nix eval '.#nixosConfigurations.uriel.config.system.build.toplevel.drvPath'`
  before building.
