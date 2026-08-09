# extras: heavy / configurable modules, toggled per-system with a real option —
# NOT by renaming files. This is NOT for per-user apps: users install their own
# apps in their hjem profile (`nixos/users/*.nix`, comment a line out to drop
# one). extras is only for machine-level heavy / configurable stuff — things
# that are big, or need their own settings later (nvidia, vicinae, and room for
# hysteria, dae, whatever). The host imports this module always and each host
# decides what it wants:
#
#   extras.enable = false;             # master OFF: nothing below turns on, period
#   extras.nvidia.enable = true;       #   (explicit overrides lose too)
#
#   extras.enable = true;              # master ON → every heavy component defaults ON
#   extras.nvidia.enable = false;      # fine-tune one down
#
# Everything is one `inheritFrom` gradient (pluieflake's `mkCatppuccinOptions`
# idea): each component's `enable` defaults to and is ANDed with the level above
# via `apply`. A HARD `extras.enable` master sits on top — when it's OFF nothing
# below can activate. Master-kill is centralized in ONE helper, so the heavy
# submodules (imported unconditionally, since imports can't reference `config`)
# never forget it: they just read their own `config.extras.<x>.enable`.
{ lib, self, ... }: {
  flake.nixosModules.extras =
    { config, ... }:
    let
      cfg = config.extras;

      # component enable: default = value of `inheritFrom`, apply = inherited && v
      mkComponent = inheritFrom: description:
        lib.mkOption {
          type = lib.types.bool;
          default = inheritFrom;
          apply = v: inheritFrom && v;
          description = description;
        };
    in
    {
      options.extras = {
        enable = lib.mkEnableOption "the heavy/configurable extras bundle (master switch; nothing below can turn on while it's OFF)";

        nvidia.enable = mkComponent cfg.enable "the NVIDIA GPU driver stack (inherits extras.enable)";
        vicinae.enable = mkComponent cfg.enable "the vicinae CLI (inherits extras.enable)";
      };

      # heavy submodules gate themselves off their (master-ANDed) `enable`.
      imports = [
        self.nixosModules.nvidia
        self.nixosModules.vicinae
      ];
    };
}