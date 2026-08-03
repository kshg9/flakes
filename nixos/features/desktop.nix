{ self, ... }: {
  flake.nixosModules.desktop = { pkgs, config, ... }: let
    selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}";
  in {
    imports = [
      self.nixosModules.pipewire
      self.nixosModules.noctalia
    ];

    # SDDM is the login manager; qylock's module installs + activates its theme
    # (programs.qylock.sddm.enable, see qylock.nix). niri is the only session —
    # the wrapped niri provides the wayland-sessions/niri.desktop entry
    # (NIRI_CONFIG baked into its units).
    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.displayManager.sessionPackages = [
      selfpkgs.niri
    ];
    systemd.packages = [ selfpkgs.niri ];

    # capitaine-cursors for the greeter (SDDM runs its own X cursor before the
    # session starts; without a theme it shows the stock X cursor). niri gets
    # its own cursor block in the wrapper (wrappedPrograms/niri.nix).
    services.displayManager.sddm.settings.Theme.CursorTheme = "capitaine-cursors";
    services.displayManager.sddm.settings.Theme.CursorSize = 24;

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    programs.firefox.enable = true;

    environment.systemPackages = [
      pkgs.firefox
      pkgs.wl-clipboard
      pkgs.brightnessctl
      pkgs.capitaine-cursors
      selfpkgs.niri
      selfpkgs.terminal
    ];

    fonts.packages = with pkgs; [
      nerd-fonts.commit-mono
      ubuntu-sans
    ];

    fonts.fontconfig.defaultFonts = {
      serif = [ "Ubuntu Sans" ];
      sansSerif = [ "Ubuntu Sans" ];
      monospace = [ "CommitMono Nerd Font Mono" ];
    };

    time.timeZone = "Asia/Kolkata";

    i18n.defaultLocale = "en_IN";
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

    services.upower.enable = true;
    security.polkit.enable = true;

    hardware = {
      enableAllFirmware = true;
      bluetooth.enable = true;
      bluetooth.powerOnBoot = false;
    };

    # Mirrors nixpkgs' programs.niri module. gtk = default fallback portal
    # (Access/Notification/FileChooser), gnome = screencasting, gnome-keyring =
    # Secret. niri's own niri-portals.conf ships the same routing.
    xdg.portal.enable = true;
    xdg.portal.extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    xdg.portal.config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.Access" = "gtk";
      "org.freedesktop.impl.portal.FileChooser" = "gtk";
      "org.freedesktop.impl.portal.Notification" = "gtk";
      "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
    };
    services.gnome.gnome-keyring.enable = true;
  };
}
