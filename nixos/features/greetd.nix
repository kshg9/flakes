{ inputs, self, ... }: {
  flake.nixosModules.greetd =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      desktop = self.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
      tuigreet = inputs.tuigreet.packages.${pkgs.stdenv.hostPlatform.system}.tuigreet;
    in
    {
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${lib.getExe tuigreet} --remember --remember-session --time --user-menu --cmd ${lib.getExe desktop}";
          };
        };
      };

      # Cache directory for --remember* features, persists across reboots
      persistance.cache.directories = [
        "/var/cache/tuigreet"
      ];

      systemd.tmpfiles.rules = [
        "d /var/cache/tuigreet 0755 greeter greeter -"
      ];
    };
}
