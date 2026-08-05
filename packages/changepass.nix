{
  perSystem =
    { pkgs, ... }:
    {
      # changepass: impermanence-friendly password change. Impermanence wipes
      # /etc/shadow every boot, so `passwd` changes don't survive. Instead the
      # hash lives in /persist/passwords/<user>, re-applied each boot via the
      # host's users.users.*.hashedPasswordFile. This writes the new hash to
      # that file AND updates /etc/shadow immediately (no reboot needed).
      #
      # --root CHROOT_DIR targets an installed system (the installer ISO's
      # urielOS uses it to seed the initial password at /mnt/persist/passwords).
      packages.changepass = pkgs.writeShellApplication {
        name = "changepass";
        runtimeInputs = [
          pkgs.shadow
          pkgs.whois
        ];
        # Plain shell file (no Nix `${…}` escaping). `.sh` is in the .gitignore
        # allowlist, so it's part of the flake source and lands in the store via
        # builtins.readFile.
        text = builtins.readFile ./changepass.sh;
      };
    };
}
