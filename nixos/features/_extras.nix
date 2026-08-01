{ self, ... }: {
  flake.nixosModules.extras = {
    imports = [
      self.nixosModules.nvidia
      self.nixosModules.printer
      self.nixosModules.vicinae
      self.nixosModules.cachix
    ];
  };
}
