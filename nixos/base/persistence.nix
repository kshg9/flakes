{
  flake.nixosModules.base = { lib, ... }: {
    options.persistence = {
      enable = lib.mkEnableOption "enable persistence";

      nukeRoot.enable = lib.mkEnableOption "Destroy /root on every boot.";

      luksName = lib.mkOption {
        type = lib.types.str;
        default = "enc";
        description = ''
          LUKS mapper name (the device name after cryptsetup open,
          becomes /dev/mapper/<name>).
        '';
      };

      user = lib.mkOption {
        default = "username";
        description = ''
          Main user
        '';
      };

      directories = lib.mkOption {
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
        default = [ ];
        description = ''
          directories to persist
        '';
      };

      files = lib.mkOption {
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
        default = [ ];
        description = ''
          files to persist
        '';
      };

      data.directories = lib.mkOption {
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
        default = [ ];
        description = ''
          directories to persist
        '';
      };

      data.files = lib.mkOption {
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
        default = [ ];
        description = ''
          files to persist
        '';
      };

      cache.directories = lib.mkOption {
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
        default = [ ];
        description = ''
          directories to persist
        '';
      };

      cache.files = lib.mkOption {
        type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
        default = [ ];
        description = ''
          files to persist
        '';
      };
    };
  };
}
