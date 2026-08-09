# hjem-ext: a tiny, self-contained program-manager for hjem.
#
# Registers ONE shared option inside every hjem user:
#
#   hjem.users.<user>.ext.programs.<name> = {
#     enable     = true;
#     settings   = { … };        # TOML-friendly value
#     configPath = "kitty/kitty.conf";   # path under ~/.config, default <name>/config.toml
#   };
#
# enabled entries are rendered with `pkgs.formats.toml` and written to
# `~/.config/<configPath>`. The global catppuccin palette is injected into
# hjem modules as `ctp` (via `hjem.specialArgs`), so generators can theme.
#
# Deletion note: module code may not `config.ext.programs` at evaluation
# (`lib.mkIf` guards each file). Enabled-name handling is purely declarative.
{
  inputs,
  self,
  ...
}: {
  # `ctp` arrives via the nixosSystem `specialArgs` (see hosts/*/configuration.nix) —
  # `config.flake` is a flake-parts namespace and is NOT visible from NixOS modules.
  flake.nixosModules.hjemExt = {
    ctp,
    lib,
    pkgs,
    ...
  }: {
    # hand the theme to every hjem user module, accessible as the `ctp` arg
    hjem.specialArgs = { inherit ctp; };
    hjem.extraModules = [
      # noctalia's own hjem module → gives `programs.noctalia`, which validates
      # and writes `~/.config/noctalia/config.toml` per-user. Broke it out here
      # (not in the extraModules cell with ext.programs) so a noctalia-less user
      # still works; only profiles that set `programs.noctalia` get it.
      inputs.noctalia.hjemModules.default
      ({
        config,
        lib,
        pkgs,
        ...
      }: let
        toml = pkgs.formats.toml { };
      in {
        options.ext.programs = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule (
            { name, ... }:
            {
              options = {
                enable = lib.mkEnableOption "hjem-ext manages this program";
                settings = lib.mkOption {
                  type = toml.type;
                  default = { };
                };
                configPath = lib.mkOption {
                  type = lib.types.str;
                  default = "programs/${name}/config.toml";
                };
              };
            }
          ));
          default = { };
        };

        config.xdg.config.files = lib.mkMerge (
          lib.mapAttrsToList (name: prog:
            lib.mkIf prog.enable {
              "${prog.configPath}" = {
                generator = toml.generate name;
                value = prog.settings;
              };
            })
          config.ext.programs
        );
      })
    ];
  };
}