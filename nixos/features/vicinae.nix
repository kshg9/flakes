{ inputs, ... }: {
  flake.nixosModules.vicinae = { ... }: { };

  perSystem = { system, ... }: {
    packages.vicinae = inputs.vicinae.packages.${system}.default;
  };
}
