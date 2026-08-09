{ self, ... }: {
  flake.nixosModules.desktop = { pkgs, config, lib, ... }: {
    imports = [
      self.nixosModules.pipewire
      self.nixosModules.noctalia
    ];

    services.xserver.enable = true;

    # Minimal default SDDM configuration with Bibata cursor
    services.displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm;
      extraPackages = [ pkgs.bibata-cursors ];
      # Force cursor theme via X resources so the greeter picks it up reliably
      setupScript = let
        xresources = pkgs.writeText "xresources" ''
          Xcursor.theme: ${config.environment.variables.XCURSOR_THEME}
          Xcursor.size: ${config.environment.variables.XCURSOR_SIZE}
        '';
      in ''
        ${pkgs.xrdb}/bin/xrdb -merge ${xresources}
      '';
      settings = {
        General = {
          InputMethod = "";
        };
        Theme = {
          CursorTheme = "Bibata-Modern-Ice";
          CursorSize = 28;
          FacesDir = "/etc/sddm/faces";
        };
      };
    };


    services.displayManager.sessionPackages = [
      pkgs.niri
    ];
    systemd.packages = [ pkgs.niri ];

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Universal cursor for niri, GTK/Qt, and Xwayland apps
    environment.variables = {
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "28";
    };

    # firefox is installed per-user via hjem (nixos/users/base.nix) — no
    # programs.firefox here (that would duplicate it system-wide).

    # App packages (browser/office/terminal/controls) now live in the per-user
    # hjem profile (nixos/users/base.nix). SystemPackages here only carries what
    # the desktop *session* needs before/outside any user profile: the compositor
    # (niri) and system-wide assets like cursor themes.
    environment.systemPackages = [
      pkgs.niri
      pkgs.bibata-cursors
    ];

    fonts.packages = with pkgs; [
      nerd-fonts.commit-mono
      ubuntu-sans
      atkinson-hyperlegible-next
    ];

    fonts.fontconfig.defaultFonts = {
      serif = [ "Ubuntu Sans" ];
      sansSerif = [ "Ubuntu Sans" ];
      monospace = [ "CommitMono Nerd Font Mono" ];
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
