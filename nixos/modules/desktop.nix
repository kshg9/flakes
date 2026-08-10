# desktop.nix — shared desktop plumbing (SDDM, cursors, fonts, portals).
#
# Window-manager-specific config lives in desktop-niri.nix / desktop-labwc.nix
# (and future desktop-*.nix). Each WM gates itself behind its own
# `config.desktop.wm.<name>.enable` option defined here. Hosts flip the
# booleans they want:
#
#   desktop.wm.niri.enable  = true;   # niri + noctalia
#   desktop.wm.labwc.enable = true;   # labwc + sfwbar + Tail-R theme
#
# Both can be ON simultaneously — SDDM shows all enabled sessions.
{ self, ... }: {
  flake.nixosModules.desktop = { pkgs, config, lib, ... }: {
    imports = [
      self.nixosModules.pipewire
      self.nixosModules.noctalia
      self.nixosModules.desktop-niri
    ];

    # ── option interface ───────────────────────────────────────────────
    options.desktop = {
      configNiri.enable  = lib.mkEnableOption "the Niri config (niri + noctalia bar + dotfiles)";
      # configRiver.enable = lib.mkEnableOption "the RiverWM config (using TVL reka module; built from source when enabled)";
    };

    # ── shared desktop config (always-on when desktop module is imported) ──
    config = {
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

      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # Universal cursor for niri, GTK/Qt, and Xwayland apps
      environment.variables = {
        XCURSOR_THEME = "Bibata-Modern-Ice";
        XCURSOR_SIZE = "28";
      };

      environment.systemPackages = [
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
    };
  };
}
