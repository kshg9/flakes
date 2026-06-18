{ self, ... }: {
  flake.nixosModules.desktop = { pkgs, config, ... }: let
    selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}";
  in {
    imports = [
      self.nixosModules.pipewire
    ];

    programs.niri.enable = true;
    programs.niri.package = selfpkgs.desktop;

    environment.systemPackages = [
      selfpkgs.terminal
      selfpkgs.vicinae
      pkgs.firefox
      pkgs.wl-clipboard
    ];

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      ubuntu-sans
    ];

    fonts.fontconfig.defaultFonts = {
      serif = [ "Ubuntu Sans" ];
      sansSerif = [ "Ubuntu Sans" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
    };

    time.timeZone = "Asia/Kolkata";
    i18n.defaultLocale = "en_US.UTF-8";

    services.upower.enable = true;
    security.polkit.enable = true;

    hardware = {
      enableAllFirmware = true;
      bluetooth.enable = true;
      bluetooth.powerOnBoot = true;
    };

    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
