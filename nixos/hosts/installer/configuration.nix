{
  inputs,
  self,
  ...
}:
let
  maximizer = self.packages.x86_64-linux.maximizer;
in
{
  flake.nixosConfigurations.installer = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostInstaller
    ];
  };

  flake.nixosModules.hostInstaller =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [
        # official NixOS graphical installer CD, birdee-style: X server + gparted/
        # firefox/vim/nano, no desktop environment. The live session below boots
        # straight into a maximized kitty running tmux — the install is the
        # `urielOS` terminal alias.
        "${modulesPath}/installer/cd-dvd/installation-cd-graphical-base.nix"
      ];

      # birdee-style fullscreen terminal session (kitty + tmux) instead of a DE.
      # lightdm autologin into a kitty that `maximizer` resizes to fill the screen
      # (vendored Xlib program in packages/maximizer; no window manager needed).
      services.xserver.displayManager.lightdm.enable = true;
      services.displayManager.autoLogin = {
        enable = true;
        user = "nixos";
      };
      services.displayManager.defaultSession = "kitty-installer";
      services.xserver.desktopManager.session = [
        {
          name = "kitty-installer";
          start = ''
            ${pkgs.kitty}/bin/kitty --title kitty-installer -e bash -c '${maximizer}/bin/maximizer kitty-installer > /dev/null 2>&1 & exec ${pkgs.tmux}/bin/tmux new -A -s install' &
            waitPID=''$!
          '';
        }
      ];

      # Embed this flake's source at /nixos on the ISO (accessible at /iso/nixos
      # in the live environment, since the ISO is mounted at /iso).
      # and install exactly the config the ISO was built from.
      isoImage.contents = [
        {
          source = inputs.self;
          target = "/nixos";
        }
      ];
      # → ./result/iso/flakes-installer.iso
      image.baseName = lib.mkForce "flakes-installer";

      nixpkgs.config.allowUnfree = true;
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "pipe-operators"
        ];
        show-trace = true;
      };

      # pinned disko + terminals on PATH (kitty/tmux for the live session)
      environment.systemPackages = [
        inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
        pkgs.kitty
        pkgs.tmux
      ];

      # one-shot installer. Usage: urielOS [target] [user]
      #   target: flake config to install (default uriel)
      #   user:   account to set a password for (default kdj)
      #   each machine has its own disko config (`nixos/hosts/<target>/disko.nix`)
      #   with the disk hardcoded — no args, no overrides.
      #   the flake source lives at /iso/nixos (the ISO is mounted at /iso).
      environment.shellAliases = {
        urielOS = "${pkgs.writeShellScript "urielOS" ''
          set -e
          target=''${1:-uriel}
          username=''${2:-kdj}
          sudo disko --mode destroy,format,mount --flake /iso/nixos#"$target"
          sudo nixos-install --flake /iso/nixos#"$target"
          echo "set a password for user $username"
          sudo passwd --root /mnt "$username"
          mkdir -p "/mnt/home/$username"
          cp -r /iso/nixos "/mnt/home/$username/flakes"
          sudo chmod -R go-rwx "/mnt/home/$username/flakes"
          sudo chown -R "$username:users" "/mnt/home/$username/flakes"
        ''}";
      };
    };
}
