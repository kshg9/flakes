{ self, ... }: {
  flake.nixosModules.desktop = { pkgs, config, ... }: {
    imports = [
      self.nixosModules.pipewire
      self.nixosModules.noctalia
    ];

    # SDDM is the login manager, stock theme — plain and simple. niri is the
    # only session. niri + kitty are now stock nixpkgs (their wrappers are gone)
    # with configs as hjem dotfiles in nixos/users/files/ (niri config.kdl in
    # kdj.nix, kitty.conf shared in base.nix) — themed from flake.ctp.
    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.displayManager.sessionPackages = [
      pkgs.niri
    ];
    systemd.packages = [ pkgs.niri ];

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # One cursor definition, sourced once from nixpkgs. niri picks it up via its
    # default "auto" cursor (reads XCURSOR_THEME/XCURSOR_SIZE), Xwayland apps via
    # the XCURSOR_* env vars, and the SDDM greeter via the explicit [Theme] keys
    # below (the greeter runs before login, so it can't read session env vars).
    environment.variables = {
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "32";
    };
    services.displayManager.sddm.settings.Theme = {
      CursorTheme = "Bibata-Modern-Ice";
      CursorSize = 32;
    };

    # firefox is installed per-user via hjem (nixos/users/base.nix) — no
    # programs.firefox here (that would duplicate it system-wide).

    # App packages (browser/office/terminal/controls) now live in the per-user
    # hjem profile (nixos/users/base.nix). SystemPackages here only carries what
    # the desktop *session* needs before/outside any user profile: the compositor
    # (niri) and its autostarted helpers.
    environment.systemPackages = [
      pkgs.niri
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
