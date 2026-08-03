{ self, ... }: {
  flake.nixosModules.general =
    {
      config,
      pkgs,
      ...
    }:
    let
      selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}";
    in
    {
      imports = [
        self.nixosModules.extra_hjem
      ];

      # No password here — the host sets its own password option (uriel uses
      # hashedPasswordFile → /persist/passwords/<user>, changed via `changepass`).
      users.users.${config.preferences.user.name} = {
        isNormalUser = true;
        description = "${config.preferences.user.name}'s account";
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        shell = selfpkgs.environment;
        packages = with pkgs; [
          featherpad
          opencode
          vscode-fhs
        ];
      };

      persistence.data.directories = [
        ".ssh"
      ];

      environment.systemPackages = with pkgs; [
        helix
        selfpkgs.changepass
      ];
    };
}
