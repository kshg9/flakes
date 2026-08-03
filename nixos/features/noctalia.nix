{ inputs, ... }: {
  flake.nixosModules.noctalia = { pkgs, ... }: {
    imports = [
      inputs.noctalia.nixosModules.default
    ];

    programs.noctalia = {
      enable = true;
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      # NetworkManager, Bluetooth, UPower, power-profiles-daemon (mkDefault,
      # so host/config-level enables win where they already exist).
      recommendedServices.enable = true;
    };
  };
}
