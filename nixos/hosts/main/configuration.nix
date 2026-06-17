{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.main = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostMain
    ];
  };

  flake.nixosModules.hostMain = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      self.nixosModules.base
      self.nixosModules.general
      self.nixosModules.desktop
      self.nixosModules.nix
      self.nixosModules.kanata
      self.nixosModules.printer
      self.nixosModules.impermanence
      self.nixosModules.nvidia
      self.nixosModules.vicinae

      inputs.disko.nixosModules.disko
      self.diskoConfigurations.hostMain
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.kernelPackages = pkgs.linuxPackages_latest;

    networking.hostName = "main";
    networking.networkmanager.enable = true;

    nixpkgs.config.allowUnfree = true;

    system.stateVersion = "25.11";
  };
}
