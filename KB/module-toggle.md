# Module toggle convention (`_` prefix) and `importTree`

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
file registers `nixosModules.desktop` automatically. Rename the file to `_foo.nix` and
the module **disappears from the flake entirely** — no eval, no build, no import.

## The extras toggle

`nixos/features/extras.nix` bundles heavy/optional hardware+service modules:

```nix
{ self, ... }: {
  flake.nixosModules.extras = {
    imports = [
      self.nixosModules.nvidia
      self.nixosModules.printer
      self.nixosModules.vicinae
      self.nixosModules.cachix
    ];
  };
}
```

It's imported conditionally in `nixos/hosts/uriel/configuration.nix`:

```nix
++ lib.optional (self ? nixosModules.extras) self.nixosModules.extras;
```

**Toggle OFF:** `git mv nixos/features/extras.nix nixos/features/_extras.nix`
Then `self.nixosModules.extras` is unset, `lib.optional` yields nothing, and the nvidia/
printer/vicinae/cachix modules are skipped. **Currently OFF** (file is `_extras.nix`).

**Toggle ON:** `git mv nixos/features/_extras.nix nixos/features/extras.nix`

Verify a mode:
```bash
nix eval .#nixosConfigurations.uriel.config.system.build.toplevel.drvPath
# then check e.g. config.hardware.nvidia or boot.initrd.kernelModules via nix eval
```

## Same trick for individual modules

Same convention applies at the module level: e.g. `_kanata.nix`, `_niri.nix` are
disabled by prefixing with `_`.

## Fileset / git interaction (critical)

`lib.fileset.toList` operates on **git-tracked files**. Because the whole repo becomes
the flake source:

- new/renamed `.nix` files MUST be `git add`-ed (or `git mv`-ed) before they're visible
  to the flake — otherwise eval silently uses the old set
- build artifacts that get `git add -A`-ed accidentally end up in the flake source →
  they're `.gitignore`d now (`result`, `*.qcow2`), see `gotchas.md`
