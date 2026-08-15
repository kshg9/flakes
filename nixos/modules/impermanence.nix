# Impermanence tuning for the uriel desktop host: enables the persistence
# plumbing (base/persistence.nix + base/impermanence.nix), activates root-wipe,
# and declares what survives across reboots.
{
  self,
  ...
}: {
  flake.nixosModules.impermanence = { ... }: {
    imports = [
      self.nixosModules.impermanenceImpl
    ];

    persistence.enable = true;
    persistence.nukeRoot.enable = true;
    # Persist systemd backlight state across reboots so brightness set in Noctalia/brightnessctl is restored
    # Persist the sops-nix directory so the boot key survives the impermanence nuke
    # without triggering file-level bind mount race conditions.
    persistence.directories = [ 
      "/var/lib/systemd/backlight" 
      "/var/lib/sops-nix"
    ];
    # Impermanence is a uriel (desktop host) concern; kdj is the primary user
    # whose home/data are made persistent. Guests (yjh) are deliberately NOT
    # listed here — their home is left to be wiped on reboot + the guest-wipe timer.
    persistence.user = "kdj";
  };
}
