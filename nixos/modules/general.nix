{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.general =
    { pkgs, ... }:
    {
      # The hjem NixOS module is imported ONCE here (system-level), so per-user
      # modules (nixos/users/*) can safely set `hjem.users.<name>.*` without
      # colliding on shared `_module.args`.
      imports = [
        inputs.hjem.nixosModules.default

        # hjem-ext: adds `ext.programs.<name>` to every hjem user + hands the
        # catpccuccin palette to hjem as `ctp`.
        self.nixosModules.hjemExt
      ];

      # NOTE: global nixpkgs settings (allowUnfree + overlay) live in
      # self.nixosModules.nixpkgsConfig, imported by every host.

      # NOTE: the user account (users.users.*) and hjem profile live in
      # nixos/users/*.nix now — each user module pulls the shared base via
      # `self.userBase <name>`.

      persistence.data.directories = [
        ".ssh"
      ];

      environment.systemPackages = with pkgs; [
        # system/admin tooling that must exist before/outside any user login
        changepass
        # lightweight jq (JSON processing; handy for sops `--value-file` work)
        jaq
      ];
      
      environment.variables = {
        # Sledgehammer editor fallback
        EDITOR = "hx";
        # Force Electron/Chromium apps to run natively on Wayland
        NIXOS_OZONE_WL = "1";
      };

      time.timeZone = "Asia/Kolkata";

      services.fwupd.enable = true;

      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_IN";
        LC_IDENTIFICATION = "en_IN";
        LC_MEASUREMENT = "en_IN";
        LC_MONETARY = "en_IN";
        LC_NAME = "en_IN";
        LC_NUMERIC = "en_IN";
        LC_PAPER = "en_IN";
        LC_TELEPHONE = "en_IN";
        LC_TIME = "en_IN";
      };

      programs.fish.enable = true;

      services.upower.enable = true;
      security.polkit.enable = true;

      hardware = {
        enableAllFirmware = true;
        bluetooth.enable = true;
        bluetooth.powerOnBoot = false;
      };
    };
}