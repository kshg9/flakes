{
  self,
  ...
}: {
  flake.nixosModules.impermanence = { config, ... }: {
    imports = [
      self.nixosModules.extra_impermanence
    ];

    persistence.enable = true;
    persistence.nukeRoot.enable = true;
    # Impermanence is a uriel (desktop host) concern; kdj is the primary user
    # whose home/data are made persistent. Guests (yjh) are deliberately NOT
    # listed here — their home is left to be wiped on reboot + the guest-wipe timer.
    persistence.user = "kdj";
  };
}
