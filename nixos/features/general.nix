{ self, ... }: {
  flake.nixosModules.general = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      self.nixosModules.extra_hjem
    ];

    users.users.${config.preferences.user.name} = {
      isNormalUser = true;
      description = "${config.preferences.user.name}'s account";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      shell = self.packages.${pkgs.stdenv.hostPlatform.system}.environment;
      hashedPasswordFile = "/persist/passwd";
      initialHashedPassword = "CHANGEME";
    };

    persistance.data.directories = [
      ".ssh"
    ];
  };
}
