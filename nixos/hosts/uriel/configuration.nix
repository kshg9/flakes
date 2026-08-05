{
  inputs,
  self,
  config,
  ...
}:
{
  flake.nixosConfigurations.uriel = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostUriel
    ];
    # ctp = resolved catppuccin palette (flavor/accent hex) — flake-level value
    # injected into the NixOS module system, so NixOS/hjem modules (kdj.nix,
    # hjem-ext, …) can theme without reaching back into `config.flake`.
    specialArgs = {
      ctp = config.flake.ctpPalette;
    };
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
          self.nixosModules.nixTools
          self.nixosModules.impermanence
          self.nixosModules.keyd
          self.nixosModules.printer
          self.nixosModules.cachix

          # per-user hjem profiles (kdj = full, yjh = restricted guest)
          self.nixosModules.userKdj
          self.nixosModules.userYjh
          self.nixosModules.guestWipe

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

      # Per-user passwords live in the user modules (kdj.nix / yjh.nix) —
      # they're the owner of each account. Same mechanism as before: a file in
      # /persist/passwords/<user> re-applied on every boot via update-users-groups.

       nixpkgs.config.allowUnfree = true;

       system.stateVersion = "26.05";
    };
}
