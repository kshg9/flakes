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
        shell = pkgs.fish;
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
            imports = [
              (import ./programs/terminal.nix { inherit name; })
              (import ./programs/mpv.nix { inherit name; })
              (import ./programs/gtk.nix { inherit name; })
            ];
            
            enable = true;
            user = name;
            directory = "/home/${name}";

            files = {
              ".face".source = lib.mkIf (userIcon != null) userIcon;
              ".face.icon".source = lib.mkIf (userIcon != null) userIcon;
            };
            
            environment.sessionVariables = {
              EDITOR = "hx";
              NIXOS_OZONE_WL = "1";
              # sops CLI edits with the PERSONAL key (keeps the editing key separate
              # from each host's boot key). ~/.config/sops/age is the sops default,
              # so this is just explicitness for the age-key discovery.
              SOPS_AGE_KEY_FILE = "/home/${name}/.config/sops/age/keys.txt";
            };
          };
      };
    };
}