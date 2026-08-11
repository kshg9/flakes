# Niri tiling Wayland compositor + noctalia bar.
# Gated by `config.desktop.configNiri.enable` (defined in desktop.nix).
{ self, ... }: {
  flake.nixosModules.desktop-niri = { pkgs, config, lib, ... }:
    lib.mkIf config.desktop.configNiri.enable {
      # ── system-level compositor plumbing ──────────────────────────────
      services.displayManager.sessionPackages = [ pkgs.niri ];
      systemd.packages = [ pkgs.niri ];
      environment.systemPackages = [ pkgs.niri ];

      # Portals for Niri (Screencasting, Secret, FileChooser)
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

      # ── per-user hjem injection (all users get niri + noctalia config) ─
      hjem.extraModules = [
        ({ config, ... }: {
          # The focus-ring accent is the catppuccin default (mauve #cba6f7);
          xdg.config.files."niri/config.kdl".source = ../users/files/niri/config.kdl;

          # noctalia (the bar/shell) — validated at build time, survives
          # rebuilds declaratively.
          programs.noctalia = {
            enable = true;
            settings = {
              shell = {
                font_family = "Atkinson Hyperlegible Next";
                settings_show_advanced = true;
                avatar_path = "/home/${config.user}/.face";
              };
              theme = {
                mode = "dark";
                source = "builtin";
                builtin = "Catppuccin";
              };
              accessibility = {
                ui_scale = 1.1;
              };
              bar = {
                default = {
                  scale = 1.1;
                  position = "top";
                  thickness = 36;
                  margin_ends = 0;
                  margin_edge = 0;
                  background_opacity = 0.55;
                  radius = 0;
                  concave_edge_corners = false;
                  widget_spacing = 6;
                  capsule = true;
                  capsule_fill = "surface_variant";
                  capsule_radius = 8;
                  capsule_opacity = 0.9;
                  capsule_padding = 6;
                  start = [ "launcher" "workspaces" ];
                  center = [ "clock" ];
                  end = [
                    "tray"
                    "network"
                    "volume"
                    "battery"
                    "session"
                  ];
                };
              };
              widget = {
                clock = {
                  font_weight = 700;
                  format = "{:%-I:%M %p}";
                };
              };
              backdrop = {
                enabled = true;
                blur_intensity = 0.5;
                tint_intensity = 0.3;
              };
            };
          };
        })
      ];
    };
}
