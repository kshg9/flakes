# Shared per-user base profile — no longer a concrete user.
#
# Exposes `flake.userBase = (name: <NixOS module>)`. Every user module calls it
# with its own username to get the account + hjem defaults, then layers its
# extras on top. This is what lets multiple users coexist on one host (each
# module owns its own name) instead of keying off a single global
# `preferences.user.name`.
{
  self,
  ...
}: {
  # The hjem NixOS module itself (inputs.hjem.nixosModules.default) is imported
  # ONCE, at the system level (features/general.nix) — a per-user import would
  # collide on `_module.args.hjem-package`. Here we only contribute `hjem.*`
  # option values for the user.
  flake.userBase =
    name:
    { pkgs, lib, ... }:
    {
      # ===== NixOS account (the OS-level part only) =====
      # Fully declarative user/group management: users + groups are derived only
      # from config (`useradd`/`passwd` etc. won't create anything at runtime).
      users.mutableUsers = false;

      users.users.${name} = {
        isNormalUser = true;
        description = "${name}'s account";
        # No privileged groups by default — each user opts in via its own module
        # (kdj: wheel+networkmanager; yjh: keys only). Simply assign
        # `extraGroups` in the user's module to grant what it needs.
        extraGroups = [ ];
        shell = pkgs.environment;
      };

      environment.etc =
        let
          jpg = ../../assets + "/${name}.jpg";
          png = ../../assets + "/${name}.png";
          userIcon =
            if builtins.pathExists jpg then jpg
            else if builtins.pathExists png then png
            else null;
        in
        lib.mkIf (userIcon != null) {
          "sddm/faces/${name}.face.icon".source = userIcon;
        };

      # ===== hjem: wiring + user packages + session vars + dotfiles =====
      hjem = {
        # Our managed files overwrite whatever is already present.
        clobberByDefault = true;

        users.${name} =
          let
            findIcon = u:
              let
                jpg = ../../assets + "/${u}.jpg";
                png = ../../assets + "/${u}.png";
              in
              if builtins.pathExists jpg then jpg
              else if builtins.pathExists png then png
              else null;
            userIcon = findIcon name;
          in
          {
            enable = true;
            user = name;
            directory = "/home/${name}";

            # NOTE: the login shell (`environment` wrapper) already carries the
            # core CLI toolset — so only a small common app set, usable by every
            # user (incl. a restricted guest), lives in the base. Tooling that a
            # guest should NOT get (nix, editors, dev tools) must go into that
            # user's own module instead.
            packages = with pkgs; [
              playerctl
              brightnessctl
              bibata-cursors
              # kitty: package + its kitty.conf below are both hjem-managed (the
              # system-only `pkgs.kitty` in desktop.nix moved here so the terminal
              # is fully per-user like niri's other apps).
              kitty
            ];

            environment.sessionVariables = {
              EDITOR = "hx";
              NIXOS_OZONE_WL = "1";
              # sops CLI edits with the PERSONAL key (keeps the editing key separate
              # from each host's boot key). ~/.config/sops/age is the sops default,
              # so this is just explicitness for the age-key discovery.
              SOPS_AGE_KEY_FILE = "/home/${name}/.config/sops/age/keys.txt";
            };

            # ===== shared hjem dotfiles (kitty + yazi migrated from wrapper-modules) ===
            # kitty/yazi are now stock nixpkgs (desktop.nix / environment.nix).
            # Their whole configs are normal dotfiles sourced from files/ — the
            # wrapper-generated content was byte-captured into them (pluie-style).
            xdg.config.files = {
              "kitty/kitty.conf".source = ./files/kitty/kitty.conf;
              # palette in its own importable file: kitty.conf `include`s it, so a
              # theme swap (noctalia / colorscheme) only rewrites colors.conf.
              "kitty/colors.conf".source = ./files/kitty/colors.conf;

              # yazi: TOML config + plugin bootstrap. ~/.config/yazi is the
              # default YAZI_CONFIG_HOME (the old wrapper set it to a store dir).
              "yazi/yazi.toml".source = ./files/yazi/yazi.toml;
              "yazi/init.lua".source = ./files/yazi/init.lua;
              # full-border plugin symlinked from nixpkgs yaziPlugins (same `ln -s`
              # the wrapper did — the store path is NOT copied, just linked).
              "yazi/plugins/full-border.yazi".source =
                "${pkgs.yaziPlugins.full-border}";

              # GTK & default X cursor settings so GTK3/GTK4 apps match Niri + SDDM
              "gtk-3.0/settings.ini".text = ''
                [Settings]
                gtk-cursor-theme-name=Bibata-Modern-Ice
                gtk-cursor-theme-size=28
              '';
              "gtk-4.0/settings.ini".text = ''
                [Settings]
                gtk-cursor-theme-name=Bibata-Modern-Ice
                gtk-cursor-theme-size=28
              '';
            };

            files =
              let
                jpg = ../../assets + "/${name}.jpg";
                png = ../../assets + "/${name}.png";
                userIcon =
                  if builtins.pathExists jpg then jpg
                  else if builtins.pathExists png then png
                  else null;
              in
              {
                ".face".source = lib.mkIf (userIcon != null) userIcon;
                ".face.icon".source = lib.mkIf (userIcon != null) userIcon;
                ".icons/default/index.theme".text = ''
                [Icon Theme]
                Inherits=Bibata-Modern-Ice
              '';
              ".local/share/icons/default/index.theme".text = ''
                [Icon Theme]
                Inherits=Bibata-Modern-Ice
              '';
            };
          };
      };
    };
}