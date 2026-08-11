{ lib, config, pkgs, ... }: {
  flake.nixosModules.flutter = { lib, config, pkgs, ... }: {
    config = lib.mkIf config.extras.flutter.enable {
      hjem.users.kdj = {
        packages = with pkgs; [
          flutter
        ];
        
        environment.sessionVariables = {
          # Recommended for Flutter on Wayland
          FLUTTER_ROOT = "${pkgs.flutter}";
        };
      };
    };
  };
}
