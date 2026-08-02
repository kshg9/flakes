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
    # No password here — initialHashedPassword is a per-host, one-shot-at-creation
    # value (machine-specific; shared modules shouldn't carry one). Hosts set it
    # themselves (uriel relies on the existing /etc/shadow entry).
    users.users.${config.preferences.user.name} = {
      isNormalUser = true;
      description = "${config.preferences.user.name}'s account";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      shell = self.packages.${pkgs.stdenv.hostPlatform.system}.environment;
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
