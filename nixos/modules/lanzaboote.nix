{
  inputs,
  lib,
  ...
}: {
  flake.nixosModules.lanzaboote =
    { pkgs, ... }:
    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      # Lanzaboote replaces systemd-boot's boot signing — force it off when this
      # module is enabled (host keeps `boot.loader.systemd-boot.enable = true`
      # as the safe fallback when this file is toggled to _lanzaboote.nix).
      boot.loader.systemd-boot.enable = lib.mkForce false;

      boot.lanzaboote = {
        enable = true;

        # Secure Boot signing keys. The bundle must survive the impermanence
        # wipe, so it's persisted via `persistence.directories` below
        # (→ /persist/system/etc/secureboot).
        pkiBundle = "/etc/secureboot";

        # First-boot flow: `sbctl create-keys` generates the bundle, sbctl
        # exports .auth files to the ESP, and the NEXT reboot (firmware still in
        # Setup Mode) enrolls them via systemd-boot. autoReboot stays off so the
        # operator controls the reboot on a real machine.
        autoGenerateKeys.enable = true;
        autoEnrollKeys.enable = true;
      };

      environment.systemPackages = [
        # Debugging/verification: `sbctl status`, `sbctl verify`, manual enroll.
        pkgs.sbctl
      ];

      # The PKI bundle must survive the impermanence wipe (/etc is on the
      # nukeRoot subvol). Persisted to /persist/system/etc/secureboot.
      persistence.directories = [ "/etc/secureboot" ];
    };
}
