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
  plugins = [ { src = selfpkgs.yazi; } { src = pkgs.fishPlugins.hydro; } ];
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
