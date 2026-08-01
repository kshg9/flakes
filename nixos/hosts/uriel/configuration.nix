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
          self.diskoConfigurations.hostUriel
        ]
        # toggle heavy/optional modules: rename extras.nix -> _extras.nix to skip
        ++ lib.optional (self ? nixosModules.extras) self.nixosModules.extras;

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.hostName = "uriel";
      networking.networkmanager.enable = true;

      nixpkgs.config.allowUnfree = true;

      system.stateVersion = "26.05";

      # Interactive VM that formats a virtual disk from disko.nix and boots
      # this config. Run:
      #   nix run -L .#nixosConfigurations.uriel.config.system.build.vmWithDisko
      # (disko test mode uses passphrase "disko" for the LUKS image)
      virtualisation.vmVariantWithDisko = {
        disko.memSize = 4096;
        virtualisation.fileSystems."/persist".neededForBoot = true;
        virtualisation.fileSystems."/home".neededForBoot = true;
        virtualisation.fileSystems."/var/log".neededForBoot = true;
        boot.initrd.secrets."/tmp/secret.key" = "${pkgs.writeText "secret.key" "disko"}";
        boot.initrd.luks.devices.enc.keyFile = "/tmp/secret.key";
        # workaround: nixpkgs vmTools now requires the kernel to expose a
        # `target` attribute, but disko's image builder wraps the kernel in
        # pkgs.aggregateModules (buildEnv), which drops it. aggregateModules
        # still contains the boot image at $out/bzImage, so pass kernelImage
        # explicitly (upstream disko PR #1170). Remove once merged.
        disko.imageBuilder.pkgs = pkgs.extend (final: prev: {
          vmTools = prev.vmTools.override (args: args // { kernelImage = "bzImage"; });
        });
        # headless boot for scripted verification: serial console on stdout
        virtualisation.graphics = false;
        boot.kernelParams = [ "console=ttyS0,115200n8" ];
      };
    };
}
