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
