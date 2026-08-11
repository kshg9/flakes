{ lib, ... }: {
  flake.nixosModules.waydroid = { config, lib, ... }: {
    config = lib.mkIf config.extras.waydroid.enable {
      virtualisation.waydroid.enable = true;
    };
  };
}
