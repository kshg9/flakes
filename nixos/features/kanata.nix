{ ... }: {
  flake.nixosModules.kanata = {
    services.kanata = {
      enable = true;
      keyboards.default = {
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc
            caps)

          (defalias
            caps (tap-hold 200 200 esc lctl))

          (deflayer base
            @caps)
        '';
      };
    };
  };
}
