{ self, ... }: {
  flake.nixosModules.extras = { pkgs, ... }: {
    imports = [
      self.nixosModules.nvidia
      self.nixosModules.vicinae
    ];

    # Heavy/optional app sandbox — DISABLED by default (this file is `_extras.nix`).
    # Toggle on via `git mv nixos/features/_extras.nix nixos/features/extras.nix`.
    # Installed system-wide here (not a per-user hjem profile) so the heighteness
    # stays one global switch instead of per-account.
    environment.systemPackages = with pkgs; [
      chromium
      libreoffice
    ];
  };
}
