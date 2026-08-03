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
          self.nixosModules.printer

          inputs.disko.nixosModules.disko
          self.diskoConfigurations.uriel
        ]
        # toggle heavy/optional modules: rename extras.nix -> _extras.nix to skip
        ++ lib.optional (self ? nixosModules.extras) self.nixosModules.extras
        # qylock star-rail SDDM/login theme + quickshell lockscreen (rename
        # qylock.nix -> _qylock.nix to fall back to the plain breeze greeter)
        ++ lib.optional (self ? nixosModules.qylock) self.nixosModules.qylock;

      # Per-desktop qylock theme (default in the feature module is star-rail).
      programs.qylock.theme = "star-rail";

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.hostName = "uriel";
      networking.networkmanager.enable = true;

      # Password lives in a file on the persisted subvol (/persist/passwords/kdj),
      # read by update-users-groups on every boot — impermanence wipes /etc/shadow,
      # so the account is recreated fresh and this hash is always applied. The
      # urielOS installer seeds that file (first password); afterwards change it
      # with the `changepass` command (updates the file + /etc/shadow now).
      users.users.${config.preferences.user.name}.hashedPasswordFile =
        "/persist/passwords/${config.preferences.user.name}";

      nixpkgs.config.allowUnfree = true;

      system.stateVersion = "26.05";
    };
}
