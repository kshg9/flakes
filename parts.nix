{ inputs, ... }: {
  imports = [
    inputs.wrapper-modules.flakeModules.wrappers
  ];

  config = {
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
}
