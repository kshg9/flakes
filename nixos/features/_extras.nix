{ self, ... }: {
  flake.nixosModules.extras = {
    imports = [
      self.nixosModules.nvidia
      self.nixosModules.vicinae
      self.nixosModules.cachix
    ];
  };
}
