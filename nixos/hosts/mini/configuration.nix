{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.mini = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostMini
    ];
  };

  flake.nixosModules.hostMini =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [
        self.nixosModules.base
        self.nixosModules.general
        self.nixosModules.desktop
        self.nixosModules.nix
      ];

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.hostName = "mini";
      networking.networkmanager.enable = true;

      services.getty.autologinUser = config.preferences.user.name;

      nixpkgs.config.allowUnfree = true;

      system.stateVersion = "25.11";
    };
}
