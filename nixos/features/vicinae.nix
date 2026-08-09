# vicinae — noise suppression CLI (standalone package). Imported unconditionally
# by extras.nix; `config.extras.vicinae.enable` (master-ANDed in extras.nix) is
# the sole gate — this module currently just contributes the package and a stub
# NixOS module.
{ inputs, ... }: {
  flake.nixosModules.vicinae = { config, lib, ... }: lib.mkIf config.extras.vicinae.enable { };

  perSystem = { system, ... }: {
    packages.vicinae = inputs.vicinae.packages.${system}.default;
  };
}