# Shared construction helpers for this flake.
#
# `config.flake.nebula.mkHost` wraps `nixpkgs.lib.nixosSystem` with the shared
# specialArgs (ctpPalette, …) so every host definition is a single call instead
# of repeating the specialArgs boilerplate.
#
#   flake.nixosConfigurations.uriel = config.flake.nebula.mkHost {
#     module = self.nixosModules.hostUriel;
#   };
{ inputs, config, ... }: {
  flake.nebula.mkHost =
    {
      module,
      extraSpecialArgs ? {},
    }:
    inputs.nixpkgs.lib.nixosSystem {
      modules = [ module ];
      # ctp = resolved catppuccin palette (flavor/accent hex) — flake-level value
      # injected into the NixOS module system, so NixOS/hjem modules (kdj.nix,
      # hjem-ext, …) can theme without reaching back into `config.flake`.
      specialArgs = {
        ctp = config.flake.ctpPalette;
      } // extraSpecialArgs;
    };
}
