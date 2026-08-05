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
    { pkgs, ... }:
    {
      # ===== NixOS account (the OS-level part only) =====
      # Fully declarative user/group management: users + groups are derived only
      # from config (`useradd`/`passwd` etc. won't create anything at runtime).
      users.mutableUsers = false;

      users.users.${name} = {
        isNormalUser = true;
        description = "${name}'s account";
        # Full-access default (wheel = sudo). A restricted guest overrides this
        # in its own module (e.g. yjh.nix sets extraGroups = mkForce []).
        extraGroups = [ "wheel" "networkmanager" ];
        shell = pkgs.environment;
      };

      # ===== hjem: wiring + user packages + session vars + dotfiles =====
      hjem = {
        # Our managed files overwrite whatever is already present.
        clobberByDefault = true;

        users.${name} = {
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
          };
        };
      };
    };
}