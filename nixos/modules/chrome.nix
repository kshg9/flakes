{ lib, config, pkgs, ... }: {
  flake.nixosModules.chrome = { lib, config, pkgs, ... }: {
    config = lib.mkIf config.extras.chrome.enable {
      programs.chromium = {
        enable = true;
        extensions = [
          "ddkjiahejlhfcafbddmgiahcphecmpfh" # uBlock Origin Lite
        ];
        extraOpts = {
          "BrowserSignin" = 0;
          "SyncDisabled" = true;
          "PasswordManagerEnabled" = false;
        };
      };

    };
  };
}
