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
    let
      selfpkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
    in
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

      # pinned disko + terminals/editor on PATH (kitty/tmux for the live session)
      # selfpkgs.changepass brings whois (`mkpasswd`) + shadow (`chpasswd`) along
      environment.systemPackages = [
        inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
        pkgs.kitty
        pkgs.tmux
        pkgs.neovim
        selfpkgs.changepass
      ];

      # one-shot installer. Usage: urielOS [target] [user]
      #   target: flake config to install (default uriel)
      #   user:   account to seed an initial password for (default kdj)
      #   each machine has its own disko config (`nixos/hosts/<target>/disko.nix`)
      #   with the disk hardcoded — no args, no overrides.
      #   the flake source lives at /iso/nixos (the ISO is mounted at /iso).
      #   Seeds the config at /etc/nixos/flakes (persisted subvol — `nh` and the
      #   scripts expect it there). To work on it, the user git-clones over it:
      #   rm -rf /etc/nixos/flakes && git clone <repo> /etc/nixos/flakes.
      #   Initial password seeded via `changepass --root /mnt` → writes
      #   /persist/passwords/<user> (persists across nukeRoot; the host config's
      #   hashedPasswordFile re-applies it every boot). Later changes: `changepass`.
      environment.shellAliases = {
        urielOS = "${pkgs.writeShellScript "urielOS" ''
          set -e
          target=''${1:-uriel}
          username=''${2:-kdj}
          sudo disko --mode destroy,format,mount --flake /iso/nixos#"$target"
          sudo nixos-install --no-root-passwd --flake /iso/nixos#"$target"
          mkdir -p /mnt/persist/system/etc/nixos
          cp -r /iso/nixos /mnt/persist/system/etc/nixos/flakes
          sudo changepass --root /mnt "$username"
        ''}";
      };
    };
}
