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