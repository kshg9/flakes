# Labwc stacking Wayland compositor + sfwbar + Tail-R theme.
# Gated by `config.desktop.configLabwc.enable` (defined in desktop.nix).
{ self, ... }: {
  flake.nixosModules.desktop-labwc = { pkgs, config, lib, ... }:
    lib.mkIf config.desktop.configLabwc.enable {
      # ── system-level compositor plumbing ──────────────────────────────
      programs.labwc.enable = true;

      # ── per-user hjem injection (all users get labwc + sfwbar config) ─
      hjem.extraModules = [
        ({ pkgs, ... }: {
          packages = with pkgs; [
            labwc
            sfwbar
            swaybg
            thunar
            kitty
            wofi
            blueman
            pamixer
            psmisc
            dunst
            mpd
            ncmpcpp
            networkmanagerapplet
            pasystray
            fcitx5
            wl-clipboard
          ];

          xdg.config.files = {
            "labwc".source = ../base/files/labwcdots/config/labwc;
            "sfwbar".source = ../base/files/labwcdots/config/sfwbar;
            "kitty".source = ../base/files/labwcdots/config/kitty;
            "dunst".source = ../base/files/labwcdots/config/dunst;
            "walls".source = ../base/files/labwcdots/walls;
          };

          files = {
            ".themes/HoneyOats".source = ../base/files/labwcdots/themes/HoneyOats;
          };
        })
      ];
    };
}
