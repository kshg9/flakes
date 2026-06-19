{ inputs, lib, ... }: {
  flake.nixosModules.vicinae = { pkgs, ... }: let
    vicinaePkg = inputs.vicinae.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    nix.settings = {
      substituters = [ "https://vicinae.cachix.org" ];
      trusted-public-keys = [ "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=" ];
    };
  };

  perSystem = { system, ... }: {
    packages.vicinae = inputs.vicinae.packages.${system}.default;
  };
}
