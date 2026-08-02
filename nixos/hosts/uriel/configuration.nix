{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.uriel = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostUriel
    ];
  };

  flake.nixosModules.hostUriel =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports =
        [
          self.nixosModules.base
          self.nixosModules.general
          self.nixosModules.desktop
          self.nixosModules.nix
          self.nixosModules.impermanence
          self.nixosModules.keyd

          inputs.disko.nixosModules.disko
          self.diskoConfigurations.uriel
        ]
        # toggle heavy/optional modules: rename extras.nix -> _extras.nix to skip
        ++ lib.optional (self ? nixosModules.extras) self.nixosModules.extras;

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.hostName = "uriel";
      networking.networkmanager.enable = true;

      # One-shot password for fresh installs (only applied when the account is
      # created — the existing /etc/shadow entry is never touched). Needed so a
      # fresh ISO install of this config has a known login.
      users.users.${config.preferences.user.name}.initialHashedPassword =
        "$6$aorCtl5jemLLfqb.$30PzcF8DguLUfiZyeeORKTPCLnDPErl9G6QEYtWK44yTyKw0PMD4g3EjknNgMOTMguy.QcU8MBUGt.usregvH1";

      nixpkgs.config.allowUnfree = true;

      system.stateVersion = "26.05";
    };
}
