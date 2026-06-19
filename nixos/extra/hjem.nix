{ inputs, self, ... }: {
  flake.nixosModules.extra_hjem =
    { config, pkgs, ... }:
    let
      user = config.preferences.user.name;
      selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}";
    in
    {
      imports = [
        inputs.hjem.nixosModules.default
      ];

      config = {
        hjem = {
          users."${user}" = {
            enable = true;
            directory = "/home/${user}";
            user = "${user}";

            # Legendary Solution
            xdg.config.files."niri/config.kdl".source = "${selfpkgs.niri}/niri-config.kdl";
          };

          clobberByDefault = true;
        };
      };
    };
}
