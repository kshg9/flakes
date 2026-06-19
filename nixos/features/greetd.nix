{ self, ... }: {
  flake.nixosModules.greetd =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      desktop = self.packages.${pkgs.stdenv.hostPlatform.system}.desktop;
      tuigreet = self.packages.${pkgs.stdenv.hostPlatform.system}.tuigreet;
    in
    {
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${lib.getExe tuigreet} --cmd ${lib.getExe desktop}";
          };
        };
      };
    };
}
