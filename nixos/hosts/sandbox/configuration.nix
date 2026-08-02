{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.sandbox = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostSandbox
    ];
  };

  flake.nixosModules.hostSandbox =
    {
      config,
      pkgs,
      lib,
      modulesPath,
      ...
    }:
    {
      imports =
        [
          self.nixosModules.base
          self.nixosModules.general
          self.nixosModules.desktop
          self.nixosModules.nix
          self.nixosModules.keyd
          # qemu-vm.nix declares virtualisation.memorySize/diskSize + system.build.vm
          # at base level. This host is a VM, so applying it unconditionally is fine.
          (modulesPath + "/virtualisation/qemu-vm.nix")
        ];

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.hostName = "sandbox";
      networking.networkmanager.enable = true;

      # Disposable VM → known dev password. Password: `vm`.
      users.users.${config.preferences.user.name}.initialHashedPassword =
        "$6$XjYPyh/Kt30OoNKn$EeNci/RYnQQKgkGilJwPkh5oreAhiu16HpH2LAsAb54NrE85O5rOowZ5HQQyKUX7dTIsA5q3K7eOAtCfQtqc5/";

      nixpkgs.config.allowUnfree = true;

      system.stateVersion = "26.05";

      # Plain build-vm test box — no disko, no LUKS, no impermanence. A clean,
      # disposable OS for experimenting with declarative apps (hyprland, niri,
      # kde/plasma, home-manager/hjem variants, etc.). Nothing here touches
      # uriel's disk stack.
      virtualisation.memorySize = 4096;
      virtualisation.diskSize = 40960;
      # Headless (serial on stdout) for scripted runs:
      # virtualisation.graphics = false;
      # boot.kernelParams = [ "console=ttyS0,115200n8" ];
    };
}
