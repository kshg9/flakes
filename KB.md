# Knowledge Base

## Recent Discoveries (Tangled & SSH)
- **Tangled SSH Push Bug**: Tangled's `git@tangled.org` URL fails if your SSH agent offers the wrong key first.
- **The Fix**: Configuring `Host tangled.org` with `IdentitiesOnly yes` forces the correct key to be used, solving the issue permanently.
- **Unified FOSS Keys**: You can logically group FOSS platforms by using a single SSH key (e.g., `id_ed25519_vcs`) and a shared SSH config block (`Host codeberg.org tangled.org`), reducing key bloat.

---

## From: README.md

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


---

## From: birdee-inspiration.md

# birdeeSystems — reference config inspiration

Source: `/home/kdj/reference/birdeeSystems/` (BirdeeHub). Full context in
`/home/kdj/reference/CONTEXT.md`; this file is the "what to steal" digest mapped to
this repo's own style. It is a sibling of the dendritic pattern (flake-parts +
recursive import + `flake.modules.*` registries) but selects by **enable-toggles**
instead of deferred module refs, and makes `nix-wrapper-modules` its backbone.

## Architecture in one paragraph

`flake.nix` is just inputs; it delegates to `default.nix`, which builds a `util`
set (with `wlib = inputs.wrappers.lib`), then `flake-parts.lib.mkFlake` imports
every `common/**/module.nix` via a **recursive named-file import**
(`util/import.nix:7-34` — walks dirs, imports the file named `module.nix`, passes
`{ inputs, util, moduleNamespace }`). Those feature modules eagerly register into
`flake.modules.nixos.*`, `flake.modules.homeManager.*`, `flake.wrappers.*`. Configs
then pull in *everything* with `builtins.attrValues self.modules.nixos` and toggle
via `birdeeMods.<name>.enable = true`. Host/home naming uses `user@host`.

Key line index: `flake.nix:170` (delegate), `default.nix:27-34` (recImport),
`default.nix:189` (attrValues splat), `util/import.nix` (recImport/importApply),
`common/flakeModules/wrappers.nix:10-17` (wrapper→module splat).

## Stealable ideas (ranked)

1. **Wrapper auto-splat into all module systems** — `common/flakeModules/wrappers.nix`:
   `mapAttrs (_: v: v.install) config.flake.wrappers` → `flake.modules.{nixos,homeManager,darwin,generic}`.
   One wrapper module = install module everywhere. Our repo already uses
   `flake.wrappers.*` (see `KB/terminal-wrapper.md`) but pulls installs by hand; this
   removes that bookkeeping.
2. **Wrapped zsh as login shell** — `default.nix:145`:
   `users.users.<name>.shell = config.wrappers.zsh.wrapper`. The fully-configured
   shell (aliases/starship/history) is the real login shell, no home-manager needed.
   We could do the same with `selfpkgs.environment` as login shell.
3. **`configsPerSystem` data-driven output generator** — `common/flakeModules/configsPerSystem.nix`:
   declare configs as *data* under a typed `perSystem` option (`freeformType =
   attrsRecursive`), auto-derive `hostname`/`username` from `user@host`, and the
   flakeModule emits `legacyPackages.${system}.{nixosConfigurations,homeConfigurations,diskoConfigurations}`.
   Interesting but heavier than our current single-host setup — worth revisiting if we
   grow more hosts.
4. **disko as per-host wrapped packages** — `configsPerSystem.nix:61-117` +
   `common/disko/`: a `subWrapperModuleWith` serializes a disko module to `disko.json`,
   wraps disko with `--flake <tmp>#<name>`, output lands at
   `legacyPackages.<sys>.diskoConfigurations.<name>` → `nix run .#diskoConfigurations.<profile>`.
   Profiles share the **same disk name** (`birdeeOSSD`) so one profile's image can boot a
   machine configured with another. Our repo already has `diskoImages`; the `--flake`
   wrapper trick and shared disk-name convention are the new bits.
5. **`HMasModule` + `usermod` helpers** — `default.nix:122-158`: factor home-manager
   into a NixOS module so bare OS installs get the identical user config as standalone
   `homeConfigurations`.
6. **Nested wrapper composition** — `common/features/wezterm/module.nix:19-39`: a
   wrapper embeds other wrappers as `subWrapperModule` options; `wezterm.wrap
   { withLauncher = true; wrapZSH = true; }` composes wezterm→tmux→zsh→starship→git
   into one `default_prog`.
7. **`constructFiles` sidecar binaries** — `common/features/tmux/module.nix:103-115`
   (attach-or-create `tx` launcher), `bemenu` (`bemenu-recency`). One wrapper output can
   ship multiple binaries with custom builders.
8. **`install.modules.*` + `mkWrapperExtension`** — `tmux/module.nix:116-146`: declare
   options *only* on the nixos install module (e.g. `utempter` driving
   `security.wrappers`), so platform-specific extras don't pollute the core wrapper.
9. **Overlay DAG with enable/order** — `common/flakeModules/overlay.nix`: overlays are
   typed spec entries topo-sorted via `wlib.dag.unwrapSort "overlays"` into
   `flake.overlist`, injected as `_module.args.pkgs` overlays. Cleaner than our current
   overlay handling.
10. **i3MonMemory two-phase monitor hotplug** — `common/features/i3MonMemory/module.nix`:
    udev (system half) writes `$RANDOM` to a shared trigger file; home half runs an
    inotify user service that re-applies xrandr + restores i3 workspaces. Template for
    any "hardware event → user-session action" feature; per-host `monitorScriptDir`
    injected per config.

## Divergences from the dendritic pattern

- Discovery: their `util.recImport` picks one `module.nix` per dir (not every `*.nix`
  like denful/import-tree). Our repo uses fileFilter importTree — keep ours.
- Registration: they **eagerly** register modules and select by enable-toggles
  (`builtins.attrValues self.modules.nixos`); dendriticWillowispll uses deferred module
  refs. Our `flake.nixosModules.*` registry is closer to theirs but we hand-import per
  host; the "splat-all + toggle" idea (item 1) is the takeaway.

## Rules from AGENTS.md to respect if adapting

- Adapt in this repo's style (`selfpkgs`, `_`-toggle), don't copy wholesale.
- New `.nix` files need `git add -A` before the flake sees them (fileset trap).
- Verify with the eval gate (`nix eval .#nixosConfigurations.uriel.config.system.build.toplevel.drvPath`).


---

## From: disko.md

# disko specifics

Verified against disko source at pinned rev `ff8702b4` (store path
`/nix/store/w2c23ykc12mswlg8hrrjzb5gv9gvkzwq-source`).

## Test-mode LUKS password

When `IN_DISKO_TEST=1` is set, `lib/types/luks.nix` (`askPassword`) uses:

```sh
export password=disko
```

`IN_DISKO_TEST=1` is exported automatically whenever `disko.testMode = true`, and
`testMode` is force-set by **both** `make-disk-image.nix`'s `systemToInstall` and
`interactive-vm.nix`. So during `vmWithDisko` image creation the `enc` LUKS device
(deduplicate: `settings.askPassword` defaults true — no `passwordFile`/`keyFile` set)
formats silently with passphrase `disko`, no prompt.

You can also set `IN_DISKO_TEST=1` by hand to script fully non-interactive
`nix run github:nix-community/disko -- --mode destroy,format,mount`.

## imageSize is mandatory

`lib/make-disk-image.nix` runs `qemu-img create ... ${disk.imageSize}` per disk. Missing
`imageSize` → eval error. Current value on `disk.main`: `"50G"`. It is only used by the
image builder — the real machine's disko run never touches it (harmless).

## Post-boot unlock (separate mechanism)

The keyfile pair in `vmVariantWithDisko` is **not** the format-time password; it's the
standard `boot.initrd.luks` mechanism for the *subsequent* boot:

```nix
boot.initrd.secrets."/tmp/secret.key" = "${pkgs.writeText "secret.key" "disko"}";
boot.initrd.luks.devices.enc.keyFile = "/tmp/secret.key";
```

- `boot.initrd.secrets` values must be **unquoted store paths** (an assertion in
  `stage-1.nix:749` rejects derivations and non-store strings — see `gotchas.md`).
- Works because disko's test passphrase `disko` matches the keyfile content.

## imageBuilder options (`module.nix`)

| Option | Default | Purpose |
| --- | --- | --- |
| `disko.imageBuilder.pkgs` | `pkgs` | whole pkgs set for the image builder (use to patch `vmTools`) |
| `disko.imageBuilder.kernelPackages` | `config.boot.kernelPackages` | swap kernel for cross/foreign builds — does NOT fix the vmTools error |
| `disko.imageBuilder.copyNixStore` | `true` | false in the VM path (interactive-vm sets it) |
| `disko.imageBuilder.extraConfig` | `{}` | extra module config for the disk-image *build* system |
| `disko.tests.extraConfig` | `{}` | extra config composed into `vmVariantWithDisko` AND `installTest` |
| `disko.imageBuilder.qemu` | `null` | qemu emulator string (binfmt cross-building) |

## installTest / nixos-anywhere — vmTools-free alternatives

Neither goes through `make-disk-image.nix`/`vmTools`, so both are immune to the
`kernel.target` bug class:

- `config.system.build.installTest` — via `diskoLib.testLib.makeDiskoTest` →
  standard nixpkgs `make-test-python.nix` driver. Deterministic CI pass/fail:
  `nix build -L '.#nixosConfigurations.uriel.config.system.build.installTest'`
- `nixos-anywhere --vm-test` — boots a real kexec installer VM, runs the identical
  disko + nixos-install sequence, feeds LUKS keys:
  `nix run github:nix-community/nixos-anywhere -- --flake .#uriel --vm-test --disk-encryption-keys /tmp/secret.key <(echo -n disko)`

`vmWithDisko` remains the choice for interactive poking at the real config.


---

## From: gotchas.md

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

`extras.enable = false` in `nixos/hosts/uriel/configuration.nix` means nvidia/vicinae/heavy
apps are skipped in evals. Printer is imported directly by `uriel`, outside extras. When
debugging nvidia/boot modules, remember which mode you're in —
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


---

## From: hjem-guide.md

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


---

## From: impermanence.md

# Impermanence

Uses `nix-community/impermanence` wrapped in a custom `persistence` module
(`nixos/features/impermanence.nix` → `nixos/extra/impermanence.nix`).

## Enabling

```nix
persistence.enable = true;
persistence.nukeRoot.enable = true;   # initrd rollback service (see below)
persistence.user = config.preferences.user.name;  # "kdj"
```

## What is persisted

- `/persist/userdata` — user directories + files (declared in `config.persistence.data.*`)
- `/persist/usercache` — cache dirs/files (`config.persistence.cache.*`)
- `/persist/system` — system dirs/files: `/etc/nixos`, `/var/log`, `/var/lib/{bluetooth,nixos,systemd/coredump}`,
  `/etc/NetworkManager/system-connections`, `/tmp`, plus `/etc/machine-id`, `/etc/lact/config.yaml`,
  `/var/keys/secret_file`
- `/home`, `/var/log`, `/persist` are `neededForBoot = true` subvolumes

## Rollback service (`boot.initrd.systemd.services.rollback`)

Runs in the initrd, `after = systemd-cryptsetup@enc`, `before = sysroot.mount`:

1. mount LUKS volume (`/dev/mapper/enc`) at subvol `/`
2. delete all child subvolumes of `/root`, then delete `/root`
3. `btrfs subvolume snapshot /mnt/root-blank /mnt/root` — restore pristine template
4. umount

Requirements on first install (documented in `disko.nix`):
- `root-blank` must exist and be made read-only:
  ```
  mount /dev/mapper/enc /mnt -o subvol=/
  btrfs property set /mnt/root-blank ro true
  umount /mnt
  ```

## VM interplay

Because rollback and persistence run in the initrd against `/dev/mapper/enc`, the VM
must:

- mount `/persist`, `/home`, `/var/log` with `neededForBoot` — otherwise boot fails
  waiting on mount units (set in `vmVariantWithDisko`)
- unlock LUKS non-interactively via keyfile (`boot.initrd.secrets` + `luks.keyFile`),
  otherwise rollback never runs

Verified in the VM: `Rollback BTRFS root subvolume to a pristine state` finishes, then
all persisted subvolumes mount.

## Passwords under impermanence

`passwd` writes to `/etc/shadow`, which `nukeRoot` wipes every boot — so normal
password changes never survive. Instead:

- the hash lives at `/persist/passwords/<user>` (on the persisted subvol);
- the host sets `users.users.<name>.hashedPasswordFile = "/persist/passwords/<user>"`.
  NixOS reads that file **each activation** (update-users-groups.pl), and since
  `/etc/shadow` is wiped, the account is recreated fresh every boot → the file
  hash is always applied. (`hashedPasswordFile` on its own = no NixOS warning;
  combining it with `initialHashedPassword` triggers the "multiple password
  options" warning.)
- **change the password with `changepass`** (`packages/changepass.nix`, on the
  system via `general.nix`): prompts like `passwd`, writes the new hash to
  `/persist/passwords/<user>` AND applies it to the live `/etc/shadow` via
  `chpasswd -e` (no reboot needed). Run with `sudo`. Supports
  `--root CHROOT_DIR` (used by the installer to seed `/mnt/persist/passwords`).
- **bootstrap**: the `urielOS` installer calls `changepass --root /mnt <user>`
  during install, seeding `/mnt/persist/passwords/<user>`, so a fresh ISO
  install boots with a known login.

## LUKS name

LUKS device is named `enc` (from `disko.nix`). Used in:
- rollback service: `systemd-cryptsetup@enc`, `/dev/mapper/enc`
- VM keyfile: `boot.initrd.luks.devices.enc.keyFile`
- `config.persistence.luksName` (module option)


---

## From: installer-iso.md

# Installer ISO (minimal, birdee-style)

Borrowed from BirdeeHub's `birdeeSystems` (`systems/installers/`, `scripts/isoInstaller`,
`.github/workflows/release.yml`). Builds the official NixOS **minimal graphical installer
ISO** with this flake's source baked in, so a fresh install is one command.

## The config (`nixos/hosts/installer/configuration.nix`)

- imports `"${modulesPath}/installer/cd-dvd/installation-cd-graphical-base.nix"`
  — birdee's exact choice: X server + gparted/firefox/vim/nano, **no desktop environment**.
  **No Calamares**: Calamares installs the static ISO image and knows nothing about
  disko/flakes — the real install is `urielOS`. (Birdee also dropped Calamares in their
  released `installer_mine`.)
- **Fullscreen terminal session, birdee-style**: lightdm autologin (`nixos` user) into a
  custom `desktopManager.session` that launches **kitty maximized running tmux**
  (`tmux new -A -s install`). Maximization is done by the vendored
  `packages/maximizer/` — birdee's tiny C program (`maximizer.c`, Xlib+XRandR) that finds
  a window by title substring and resizes it to fill the screen, since a raw X server has
  no window manager. Boot → big terminal, `urielOS <target>`.
- `image.baseName = lib.mkForce "flakes-installer"` → ISO named `flakes-installer.iso`
  (note: current nixpkgs uses `image.baseName`, the old `isoImage.isoBaseName` is gone).
- `isoImage.contents = [ { source = inputs.self; target = "/nixos"; } ]` — embeds the
  flake source on the ISO. In the live environment the ISO is mounted at `/iso`, so the
  flake lives at `/iso/nixos` — the alias uses this path. Installs need no git/ssh auth
  and install exactly the config the ISO was built from. (Birdee instead git-clones from
  GitHub in the alias; embedding is more robust for a private repo.)
- pinned `inputs.disko.packages.<sys>.disko` added to `systemPackages`, so the install
  alias uses the locked disko (not `nix run github:...` latest).
- `nixpkgs.hostPlatform` must be set — install-cd modules require it (uriel/sandbox get it
  from their `hardware-configuration.nix`; the installer has none).

## The one-shot install alias (`urielOS`)

Set as `environment.shellAliases.urielOS` (a `writeShellScript`). On the live ISO:

```bash
urielOS [target] [user]
#  target: config to install     (default uriel)
#  user:   initial password seed (default kdj)
#
#  1. sudo disko --mode destroy,format,mount --flake /nixos#<target>
#  2. sudo nixos-install --no-root-passwd --flake /nixos#<target>
#  3. copy /nixos → /mnt/persist/system/etc/nixos/flakes
#     (persisted subvol; bind-mounted to /etc/nixos/flakes on boot, where
#     `nh` and the scripts expect the flake)
#  4. `changepass --root /mnt <user>` → prompts, writes hash to
#     /persist/passwords/<user> (persists across nukeRoot; the host's
#     hashedPasswordFile re-applies it every boot). Later changes: `changepass`.
#
#  To work on the config, git-clone over the seed:
#  rm -rf /etc/nixos/flakes && git clone <repo> /etc/nixos/flakes
```

Each machine gets its own hardened disko config (`nixos/hosts/<target>/disko.nix`, disk
by-id hardcoded); the target name selects it — same pattern as birdee's `birdeeOS`.
`disko --flake /nixos#<target>` works because flake-parts exposes each
`diskoConfigurations.<target>` as a top-level flake output. No args, no overrides.

## Build

```bash
scripts/build-iso.sh            # → ./result/iso/flakes-installer.iso
# write to USB:
sudo dd if=result/iso/flakes-installer.iso of=/dev/sdX bs=1M status=progress
```

Big build (X + kernel). The fast gate is
`nix eval .#nixosConfigurations.installer.config.system.build.isoImage.drvPath`.

## Gotchas

- ISO embeds the git-tracked source (`inputs.self`). Dirty *untracked* files won't be in
  it — commit/stage first (`git add -A`) for a true "latest and greatest" ISO.
- `nixos-install --flake /nixos#uriel` builds uriel's full config at install time
  (impermanence/LUKS included) — network needed on the live system.
- Don't run `urielOS` on a machine whose disk you don't want wiped — `disko
  --mode destroy,format,mount` destroys partitions on the target device (per-machine
  `device` in `nixos/hosts/<target>/disko.nix`).


---

## From: module-toggle.md

# Module toggle conventions and `importTree`

## How module imports work here

`flake.nix` uses a custom flake-parts import:

```nix
isNixModule = file: file.hasExt "nix" && file.name != "flake.nix" && !lib.hasPrefix "_" file.name;
importTree = path: toList (fileFilter isNixModule path);
```

Every `.nix` file in the repo (recursively) becomes a flake-parts module **except**:

1. `flake.nix` itself
2. any file whose name starts with `_`

So an attrset like `{ flake.nixosModules.desktop = {...}: {...}; }` inside any `.nix`
file registers `nixosModules.desktop` automatically. A file named `_foo.nix` is
invisible to the flake entirely — no eval, no build, no import.

## Two ways to toggle a module

### Preferred: a real option (`options.extras` style) — no renames

Heavy/optional bundles are toggled **per-system** with a boolean option, never by
renaming files. `nixos/features/extras.nix` registers `flake.nixosModules.extras`
**always** and exposes a HARD master switch + inherited component toggles.
Separate scenarios (pick ONE in a host):

```nix
# master OFF — nothing activates, period (even explicit component overrides lose)
extras.enable = false;
extras.nvidia.enable = true;   # ignored: master is OFF

# master ON — every component defaults ON
extras.enable = true;

# master ON + fine-tune one component (vicinae stays ON)
extras.enable = true;
extras.nvidia.enable = false;
```

Scope is **machine-level heavy/configurable modules only** (nvidia, vicinae; room for
hysteria/dae). **Per-user apps are NOT extras** — each user's apps live in that
user's hjem profile (`nixos/users/*.nix`) as a plain package list; comment a line
in/out to add/remove one:

Why options, not renames:

- renaming needs `git mv` every flip (fileset trap) and churns git history
- a rename is **global** — you can't have nvidia on uriel but off on a VM
- you'd be abusing "does this module exist" (`self ? ...`) as a boolean

**Master-kill is centralized, not duplicated.** Each component option is built by
`mkComponent` which does `apply = v: cfg.enable && v` — so the *resolved*
`config.extras.<component>.enable` is already ANDed with the master. Submodules
(NVIDIA, vicinae) simply gate on their own `config.extras.<component>.enable` and
can never forget the master. This mirrors pluieflake's `mkCatppuccinOptions`
(`inheritFrom` gradient) and catppuccin/nix's `catppuccin.autoEnable` inherit
pattern. Imports are unconditional (imports can't reference `config`).

Why `apply`, not `default` alone: a plain `default = cfg.enable` would let a
host explicitly set `extras.nvidia.enable = true` while master is OFF — the
component would come on. `apply` makes the master decisive in one place.

### Legacy: the `_`-prefix rename

Still valid for a leaf module you want fully gone from eval (e.g. `_kanata.nix`).
Prefix `X.nix` → `_X.nix` to disable. Used sparingly; prefer an option when the
toggle needs to be per-system.

Verify a mode:
```bash
nix eval .#nixosConfigurations.uriel.config.system.build.toplevel.drvPath
# then check e.g. config.services.xserver.videoDrivers or boot.initrd.kernelModules
```

## Fileset / git interaction (critical)

`lib.fileset.toList` operates on **git-tracked files**. Because the whole repo becomes
the flake source:

- new/renamed `.nix` files MUST be `git add`-ed (or `git mv`-ed) before they're visible
  to the flake — otherwise eval silently uses the old set
- build artifacts that get `git add -A`-ed accidentally end up in the flake source →
  they're `.gitignore`d now (`result`, `*.qcow2`), see `gotchas.md`

---

## From: noctalia.md

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


---

## From: ruixi-inspiration.md

# ruixi-rebirth — reference config inspiration & TODOs

Reference inspiration captured from `ruixi-rebirth`'s NixOS / dotfiles configuration.

5. **Android Setup**
   - Android development & utility suite (`adb`, `scrcpy`, `android-tools`, udev rules for android devices, android-studio / SDK setup).


---

## From: secureboot.md

# Secure Boot (lanzaboote)

UEFI Secure Boot via `nix-community/lanzaboote`. Replaces systemd-boot's boot
signing with a proper keychain: kernels/initrds are signed UKIs.

## Wiring

- `flake.nix` input `lanzaboote` (github:nix-community/lanzaboote).
- `nixos/features/lanzaboote.nix` → `flake.nixosModules.lanzaboote`,
  imported by uriel via `lib.optional (self ? nixosModules.lanzaboote)`.
  Rename `lanzaboote.nix` → `_lanzaboote.nix` to fall back to systemd-boot
  (the host keeps `boot.loader.systemd-boot.enable = true` as the safe default).
- `boot.lanzaboote.pkiBundle = "/etc/secureboot"` — the db/PK/KEK signing key
  bundle. It is **persisted** (`persistence.directories = [ "/etc/secureboot" ]`
  → `/persist/system/etc/secureboot`) because `/etc` is on the nukeRoot subvol
  and would be wiped on every boot.
- `autoGenerateKeys.enable = true` → `generate-sb-keys.service` runs
  `sbctl create-keys` on first boot if `${pkiBundle}/keys` doesn't exist.
- `autoEnrollKeys.enable = true` → `prepare-sb-auto-enroll.service` exports
  PK/KEK/db `.auth` files to the ESP; the **next** reboot enrolls them via
  systemd-boot while the firmware is in Setup Mode. `autoReboot` is left OFF so
  the operator controls that reboot.

## First-time enable (manual steps on the real machine)

1. Rebuild/activate with the feature on (or fresh install). Boot twice: first
   boot generates keys + exports `.auth`; second boot (still Setup Mode)
   enrolls them.
2. If the firmware isn't in Setup Mode yet, put it there:
   - ThinkPad: Security → Secure Boot → Enable → "Reset to Setup Mode".
     **Don't** "Clear All Secure Boot Keys" (drops dbx).
   - Framework: Administer Secure Boot → delete PK/KEK/DB entries one by one
     (**not** "Erase all Secure Boot Settings" — buggy on most models).
3. Verify enrollment: `sbctl status` (user mode), `sbctl verify` (all EFI
   binaries signed), `bootctl status` (Secure Boot: enabled).
4. Manual alternative to autoEnroll: `sudo sbctl enroll-keys --microsoft`
   (add `--firmware-builtin` on Framework for vendor firmware updates).

## Notes / gotchas

- Lanzaboote currently requires systemd-boot as the underlying boot manager;
  it takes over the signing.
- `sbctl` is on the system for debugging (`environment.systemPackages`).
- **Verify UEFI + LUKS/plymouth interplay before enabling on uriel** — boot
  path is LUKS `enc` → btrfs → impermanence rollback, all in a signed initrd.
- Measured boot (`boot.lanzaboote.measuredBoot`) and TPM LUKS enrollment
  (`systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1pX`) are possible
  follow-ups; see haseebmajid.dev's Framework setup write-up.


---

## From: sops.md

# sops / sops-nix — declarative secrets

Setup captured 2026-08-09. sops-nix decrypts at boot (activation) directly to
`/run/secrets/<name>`. **TWO-KEY model** — proves out before a 2nd real host
(virt-manager, GCP-ish) lands. A sandbox VM POC validated the machinery, then
was reverted (sandbox needs no secrets) — the runbooks below are the lasting
takeaway.

- **Personal editing key** — kdj's key in `~/.config/sops/age/keys.txt`
  (sops' default location). The `sops` CLI edits with THIS key on any host.
- **Per-host BOOT key** — each host auto-generates its own
  `/var/lib/sops-nix/key.txt` (`sops.age.generateKey`). Only decrypts that
  host's secrets at boot, as root.

**Each host has its OWN secrets file** (`nixos/features/secrets/<host>.yaml`),
encrypted for kdj + that host, so no other host can decrypt it. kdj can edit
from any machine (present personal key); each host decrypts its own with its
own boot key. DON'T regress to one-key (a single shared `keyFile` gives the
CLI a host-specific key that can't edit other hosts' secrets — breaks the
moment host #2 appears) and DON'T nest all hosts' secrets in one file.

## What's in place

- `flake.nix` → `sops-nix` input (nixpkgs follows ours).
- `nixos/features/sops.nix` → `flake.nixosModules.sops` — the **generic**
  plumbing, currently imported by uriel only:
  - `sops.age.keyFile = /var/lib/sops-nix/key.txt` + `generateKey = true`.
  - `environment.systemPackages` += `sops` + `age` (the CLI + age-keygen).
  - **NO `sops.secrets.*` here** — which secrets a host decrypts is gated
    PER-HOST, declared in that host's `configuration.nix`.
- `nixos/features/impermanence.nix` — `persistence.files` includes
  `/var/lib/sops-nix/key.txt` (uriel persists the boot key).
- Per-host secret declarations (uriel):
  `sops.defaultSopsFile = ./../../features/secrets/uriel.yaml` +
  `sops.secrets.github_ssh_private_key` (kdj:users 0600) +
  `github_ssh_pubkey` (root:keys 0444) — in `hosts/uriel/configuration.nix`.
- `nixos/features/secrets/uriel.yaml` — uriel's secrets, encrypted for
  `[kdj, uriel]`.
- `.sops.yaml` (repo root) — sops gates edits by filename from repo root.
  `keys:` holds real pubkeys `&kdj` (personal) + `&uriel` (uriel boot), and the
  per-file `creation_rules` (`uriel\.yaml` → `[*kdj,*uriel]`). A creation_rule
  can only reference a key that's DEFINED above — a rule referencing an
  undefined/comment-out `&name` breaks `sops` config loading for all files.
- `nixos/users/base.nix` — hjem `environment.sessionVariables`
  `SOPS_AGE_KEY_FILE = ~/.config/sops/age/keys.txt` so the `sops` CLI always
  uses the PERSONAL key (never the host boot key), wherever you are.

## The age keys

- **Personal (kdj):** `~/.config/sops/age/keys.txt`; pubkey via
  `age-keygen -y ~/.config/sops/age/keys.txt` → paste into `.sops.yaml` `&kdj`.
  The `sops` CLI then just works (default path + SOPS_AGE_KEY_FILE → it).
  `&kdj` in `.sops.yaml` is filled with this pubkey.
- **uriel boot key:** `/var/lib/sops-nix/key.txt` generated + persisted.
  `&uriel` in `.sops.yaml` matches `sudo age-keygen -y /var/lib/sops-nix/key.txt`.
- **Future host boot key:** same pattern — its own key, its own secrets file.
  A VM that's disposable can get a key you control via a shared dir
  (`virtualisation.sharedDirectories`) + swap-and-reboot, but there's no live
  sops usage on the sandbox today.

## kdj daily — editing / adding secrets non-interactively (jaq style)

Verified on real files 2026-08-09. `sops set` is the non-interactive route.
**Correct forms** (the help text is misleading):

```bash
# 📌 `jaq -Rs .` (NO `-a` — jaq has no such flag; `-Rsa` errors: unknown flag)
# 📌 `sops set` has NO `-a` flag. `--value-file` is a BOOL; the value-path is
#    the 3rd POSITIONAL arg:  sops set --value-file FILE INDEX VALUE_PATH
#    (FILE + INDEX + VALUE = 3 positionals; omitting the 3rd → `Invalid set index format`)

# add a single secret from a file (e.g. ssh key — strips nothing, raw JSON string)
jaq -Rs . ~/.ssh/id_ed25519_gh > /tmp/gh_key.json
sops set --value-file nixos/features/secrets/uriel.yaml \
  '["github_ssh_private_key"]' /tmp/gh_key.json

jaq -Rs . ~/.ssh/id_ed25519_gh.pub > /tmp/gh_pub.json
sops set --value-file nixos/features/secrets/uriel.yaml \
  '["github_ssh_pubkey"]' /tmp/gh_pub.json

# verify + stage (fileset trap: the new/edited .yaml must be git add-ed)
sops -d nixos/features/secrets/uriel.yaml
git add nixos/features/secrets/uriel.yaml
```

Each edit re-encrypts for every recipient in the file's metadata (kdj + that
host). The `|` block respresentation is fine; `sops set` merges, so the
`hello:` demo key survives.

## Adding a NEW host (runbook)

1. **Import the module** — add `self.nixosModules.sops` to the host's
   `imports` in `nixos/hosts/<host>/configuration.nix`.
2. **Declare its secrets** there (NOT in `sops.nix`, it's generic):
   ```nix
   sops.defaultSopsFile = ./../../features/secrets/<host>.yaml;
   sops.secrets.github_ssh_private_key = { owner = "<user>"; mode = "0600"; };
   ```
   Give the user the `keys` group (e.g. `extraGroups = [ "keys" ]`) so they can
   traverse `/run/secrets` (the dir itself is root:keys 750).
3. **Make a boot key** for the host (dedicated age key; SSH keys are
   passphrase-protected here → never usable, see below). Persist it per the
   host's setup: bare metal via `persistence.files`
   (`features/impermanence.nix`); a disposable VM can swap in a key you control
   through a `virtualisation.sharedDirectories` mount + reboot.
4. **`.sops.yaml`**: add `&<host> "<pubkey>"` (from
   `sudo age-keygen -y /var/lib/sops-nix/key.txt`) + a per-file
   `creation_rules` entry `[*kdj, *<host>]`. ⚠️ define the key ABOVE the rule.
5. **Create the host's secrets file** with the jaq/sops commands above
   (recipient metadata comes from the creation_rule).
6. **`git add`** the new `<host>.yaml` — the fileset trap hides it from the
   flake otherwise. Eval-gate: `nix eval .#nixosConfigurations.<host>...drvPath`.

## SSH keys → age: NOT available here (verified 2026-08-08)

kdj's `~/.ssh/id_ed25519_gh` + `id_ed25519_termux` are **passphrase-protected**
(`ssh-keygen -y` fails; sops decrypts `failed to obtain passphrase... /dev/tty
not available`). sops-nix decrypts at boot as root without a terminal, so a
passphrase'd SSH key can NEVER be a boot key. SSH keys CAN still be added as
*sops recipients* (IDENTITY NOT) via `ssh-to-age` for multi-key setups — but
stick to dedicated generated age keys.

## kdj daily

```bash
# interactive edit of an existing secret (opens $EDITOR)
sops nixos/features/secrets/uriel.yaml
# non-interactive (jaq + sops set) — see "editing / adding secrets" above
```

Each edit re-encrypts for every key in the matching `creation_rules` group
(kdj + all hosts). Commit the changed file — it's encrypted.

## Using a secret in a NixOS/hjem module

```nix
sops.secrets.mytoken = { };                    # → /run/secrets/mytoken at boot
# reference: config.sops.secrets.mytoken.path
#   e.g. service: EnvironmentFile = [ config.sops.secrets.mytoken.path ];
#   per-secret alt file: sops.secrets.mytoken.sopsFile = ./other.yaml;
```

`regularSecrets` decrypts via `sops-install-secrets` activation script; lands
in tmpfs `/run/secrets` each boot.

## Gotchas / traps

- Define the `.sops.yaml` creation_rule ONLY when its key anchor exists —
  a rule referencing an undefined `&name` (or a commented-out key) breaks
  `sops` **config loading** for ALL files (`unknown anchor '…' referenced`).
- `sops set --value-file` needs THREE positional args (`FILE INDEX VALUE_PATH`);
  `--value-file` is a bare boolean flag, not a value-taking one. Missing the
  3rd arg → `Invalid set index format`.
- `jaq` has NO `-a` flag (`jaq -Rsa .` → `unknown flag: -a`); use `jaq -Rs .`.
  `-Rs` keeps the trailing newline in the stored value (harmless for PEM/pubkeys).
- `defaultSopsFile` is resolved relative to the DEFINING module — that's now
  each host's `configuration.nix` (`hosts/uriel/` → `../../features/secrets/…`),
  not the shared `sops.nix`.
- uriel's boot key survives only because it's in `persistence.files`,
  declared in `features/impermanence.nix`. Moving/deleting it breaks decrypts.
- Never commit an unencrypted secret.
- `sops.age.generateKey` won't overwrite an existing key.
- sops-nix only activates `generateKey`/decrypt once at least one
  `sops.secrets.*` is declared.

---

## From: terminal-wrapper.md

# Terminal wrapper facade + `selfpkgs` pattern

## The `flake.wrappers.terminal` facade

`wrappedPrograms/environment.nix` defines two related wrappers via the
`BirdeeHub/nix-wrapper-modules` input:

```nix
flake.wrappers.environment = { pkgs, ... }: let
  selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}";
in {
  imports = [ self.wrapperModules.fish ];
  binName = "fish";
  runtimePkgs = [ pkgs.git pkgs.eza ... selfpkgs.yazi selfpkgs.qalc ];
  env.EDITOR = lib.getExe pkgs.helix;
};

flake.wrappers.terminal = { pkgs, ... }: let
  selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}";
in {
  imports = [ self.wrapperModules.kitty ];
  binName = "terminal";
  shell = lib.getExe selfpkgs.environment;
};
```

- `terminal` is kitty wrapped with `--config terminal.conf` and fish as its shell.
- `binName = "terminal"` makes the installed binary literally named `terminal`.

### Why `binName = "terminal"` matters (the Plasma lesson)

The wrapper's `binName` **defaults to the wrapped program's name** (found in
makeWrapper/module.nix:693 `default = name`). vimjoyer's config omits it — his refs use
nix-computed paths so the name never matters to him.

This user's Plasma stores **raw command names** in global shortcuts. If the binary is
named `kitty`, a future terminal-swap (e.g. wrapper a different emulator) silently breaks
the existing shortcuts. A stable `terminal` name survives any backend swap.

Consequences of keeping `binName = "terminal"`:
- `result/bin/` contains: `terminal` (configured wrapper → `kitty --config terminal.conf`),
  `kitty` (RAW, unconfigured — do not rely on it), `kitten`
- nix-side references must use `lib.getExe selfpkgs.terminal`, never a hardcoded name

## The `selfpkgs` let-binding pattern

Inside each module, bind the self-packages for the current system:

```nix
let
  selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}";
in
```

Use it to reference flake-built packages (`selfpkgs.terminal`, `selfpkgs.yazi`,
`selfpkgs.environment`) from NixOS modules. Mirrors vimjoyer's `~/reference/nixconf`
pattern (`nixos/features/desktop.nix:20-25`).

## Install

`nixos/features/desktop.nix` adds the wrapper to system packages:

```nix
let selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}"; in
environment.systemPackages = [ ... selfpkgs.terminal ];
```

## To swap the terminal backend later

1. change `flake.wrappers.terminal.imports` to the new `wrapperModules.<x>`
2. keep `binName = "terminal"` (Plasma shortcuts survive)
3. keep `shell = lib.getExe selfpkgs.environment`
4. keep installing `selfpkgs.terminal` in desktop.nix


---

## From: vm-testing.md

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
screen goes black after SDDM login. The sandbox host fixes it by
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
shows the default "X". The plain SDDM setup in `desktop.nix` doesn't theme it
(package support for the cursor theme stays in systemPackages). niri gets its
own `cursor { xcursor-theme "capitaine-cursors" }` block in the wrapper, and the
package ships in `systemPackages` so it's installed for the session too.
To theme the greeter, add `services.displayManager.sddm.settings.Theme.CursorTheme
= "capitaine-cursors";` back to `desktop.nix`.

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


---

