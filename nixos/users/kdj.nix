# kdj's per-user module — layered on the shared base, owns its own name.
{
  self,
  ...
}: {
  flake.nixosModules.userKdj =
{ pkgs, ... }:
    let
      user = "kdj";
    in
    {
      imports = [ (self.userBase user) ];

      # Password lives in a file on the persisted subvol (/persist/passwords/kdj),
      # read by update-users-groups on every boot — impermanence wipes /etc/shadow,
      # so the account is recreated fresh and this hash is always applied. Change
      # it with the `changepass` command (updates the file + /etc/shadow now).
      users.users.${user}.hashedPasswordFile = "/persist/passwords/${user}";

      # ===== hjem: kdj's home profile =========================================
      # niri is now plain nixpkgs niri (desktop.nix) — no wrapped NIRI_CONFIG
      # store path. Its whole config is a normal hjem-managed dotfile at
      # `~/.config/niri/config.kdl`, sourced from files/niri/config.kdl (the
      # byte-captured output of the old wrapper's toKdl renderer, pluie-style).
      # The focus-ring accent there is the catppuccin default (mauve #cba6f7);
      # bump it there if you switch flake.ctp.accent.
      hjem.users.${user} = {
        xdg.config.files."niri/config.kdl".source = ./files/niri/config.kdl;

        # helix: kdj-only editor. Stock nixpkgs `helix` reads ~/.config/helix;
        # config.toml selects the custom kanagawa-transparent theme (inherits the
        # bundled kanagawa, unsets the opaque bg scopes → transparent).
        xdg.config.files = {
          "helix/config.toml".source = ./files/helix/config.toml;
          "helix/themes/kanagawa-transparent.toml".source =
            ./files/helix/kanagawa-transparent.toml;
        };

        # noctalia (the bar/shell) — config.toml is written by noctalia's own
        # hjem module (imported via hjem-ext), validated at build time, and now
        # survives rebuilds declaratively instead of being rewritten at runtime.
        # Matches the flake's catppuccin identity.
        programs.noctalia = {
          enable = true;
          settings = {
            shell = {
              font_family = "Atkinson Hyperlegible Next";
              settings_show_advanced = true;
            };
            theme = {
              mode = "dark";
              source = "builtin";
              builtin = "Catppuccin";
            };
            # 1.1 UI scale (non-bar shell surfaces: panels, launcher, CC).
            accessibility = {
              ui_scale = 1.1;
            };
            # 1.1 bar content scale (icons + labels inside the bar itself).
            bar = {
              default = {
                scale = 1.1;
                position = "top";
                thickness = 36;
                margin_ends = 0;
                margin_edge = 0;
                background_opacity = 0.55;
                radius = 0;
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
            # Per-widget overrides: bold, 12-hour clock.
            widget = {
              clock = {
                font_weight = 700;
                format = "{:%-I:%M %p}";
              };
            };
            # Blur the niri overview backdrop (see files/niri/config.kdl
            # `layer-rule` matching ^noctalia-backdrop). Requires Option 1 in
            # the niri compositor settings.
            backdrop = {
              enabled = true;
              blur_intensity = 0.5;
              tint_intensity = 0.3;
            };
          };
        };

        # kdj-only extras on top of the shared base. Keep the base in base.nix;
        # only what is specific to kdj goes here. This is where dev tooling lives
        # (a restricted guest like yjh never sees these).
        packages = with pkgs; [
          # kdj's personal / desktop apps
          firefox

          # dev tools specific to this founder
          vscodium
          opencode
          helix
          nixd
          statix
          nixfmt
          nix-diff
        ];
      };
    };
}