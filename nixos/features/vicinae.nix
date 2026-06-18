{ inputs, lib, ... }: {
  flake.nixosModules.vicinae = { pkgs, ... }: let
    vicinaePkg = inputs.vicinae.packages.${pkgs.stdenv.hostPlatform.system}.default;
  in {
    nix.settings = {
      substituters = [ "https://vicinae.cachix.org" ];
      trusted-public-keys = [ "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=" ];
    };

    systemd.user.services.vicinae = {
      description = "Vicinae launcher";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe vicinaePkg}";
        Restart = "on-failure";
        Environment = "USE_LAYER_SHELL=1";
      };
    };
  };

  perSystem = { system, ... }: {
    packages.vicinae = inputs.vicinae.packages.${system}.default;
  };
}
