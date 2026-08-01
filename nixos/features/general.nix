{ self, ... }: {
  flake.nixosModules.general = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      self.nixosModules.extra_hjem
    ];

    # TODO later: set users.mutableUsers = false for fully declarative users
    users.users.${config.preferences.user.name} = {
      isNormalUser = true;
      description = "${config.preferences.user.name}'s account";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      shell = self.packages.${pkgs.stdenv.hostPlatform.system}.environment;
      initialHashedPassword = "$6$aorCtl5jemLLfqb.$30PzcF8DguLUfiZyeeORKTPCLnDPErl9G6QEYtWK44yTyKw0PMD4g3EjknNgMOTMguy.QcU8MBUGt.usregvH1";
      packages = with pkgs; [
        kdePackages.kate
        opencode
        vscode-fhs
      ];
    };

    persistence.data.directories = [
      ".ssh"
    ];

    environment.systemPackages = with pkgs; [
      helix
    ];
  };
}
