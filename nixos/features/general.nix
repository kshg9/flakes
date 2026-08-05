{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.general =
    { pkgs, ... }:
    {
      # The hjem NixOS module is imported ONCE here (system-level), so per-user
      # modules (nixos/users/*) can safely set `hjem.users.<name>.*` without
      # colliding on shared `_module.args`.
      imports = [
        inputs.hjem.nixosModules.default

        # hjem-ext: adds `ext.programs.<name>` to every hjem user + hands the
        # catpccuccin palette to hjem as `ctp`.
        self.nixosModules.hjemExt
      ];

      # Overlay merges this flake's `self.packages` (wrapped programs, plain
      # packages) into nixpkgs so modules write `pkgs.niri`, `pkgs.kitty` … No
      # `selfpkgs` boilerplate needed anymore.
      nixpkgs.overlays = [ self.overlays.default ];

      # NOTE: the user account (users.users.*) and hjem profile live in
      # nixos/users/*.nix now — each user module pulls the shared base via
      # `self.userBase <name>`.

      persistence.data.directories = [
        ".ssh"
      ];

      environment.systemPackages = with pkgs; [
        # system/admin tooling that must exist before/outside any user login
        changepass
      ];
    };
}