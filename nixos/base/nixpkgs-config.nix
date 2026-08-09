{ self, ... }: {
  flake.nixosModules.nixpkgsConfig = {
    # Global nixpkgs settings for every NixOS configuration in this flake.
    nixpkgs = {
      config.allowUnfree = true;

      # Overlay merges this flake's `self.packages` (wrapped programs, plain
      # packages) into nixpkgs so modules can use `pkgs.<name>` directly.
      overlays = [ self.overlays.default ];
    };
  };
}
