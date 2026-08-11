# extras: heavy / configurable modules, toggled per-system with a real option —
# NOT by renaming files. This is NOT for per-user apps: users install their own
# apps in their hjem profile (`nixos/users/*.nix`, comment a line out to drop
# one). extras is only for machine-level heavy / configurable stuff — things
# that are big, or need their own settings later (nvidia, vicinae, and room for
# hysteria, dae, whatever).
#
# Every heavy component defaults OFF. Enable them explicitly in your host configuration:
#
#   extras = {
#     android.enable = true;
#     vicinae.enable = true;
#   };
{ lib, self, ... }: {
  flake.nixosModules.extras =
    { ... }:
    {
      options.extras = {
        nvidia.enable = lib.mkEnableOption "the NVIDIA GPU driver stack";
        vicinae.enable = lib.mkEnableOption "the vicinae CLI";
        waydroid.enable = lib.mkEnableOption "Waydroid Android container";
        chrome.enable = lib.mkEnableOption "Google Chrome / Chromium browsers";
        kube.enable = lib.mkEnableOption "Kubernetes tooling (kubectl, k3d, helm)";
      };

      imports = [
        self.nixosModules.nvidia
        self.nixosModules.vicinae
        self.nixosModules.waydroid
        self.nixosModules.chrome
        self.nixosModules.kube
      ];
    };
}