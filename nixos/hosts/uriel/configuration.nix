{
  inputs,
  self,
  config,
  ...
}:
{
  flake.nixosConfigurations.uriel = config.flake.nebula.mkHost {
    module = self.nixosModules.hostUriel;
  };

  flake.nixosModules.hostUriel =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        self.nixosModules.base
        self.nixosModules.nixpkgsConfig
        self.nixosModules.general
        self.nixosModules.desktop
        self.nixosModules.nixTools
        self.nixosModules.impermanence
        self.nixosModules.keyd
        self.nixosModules.printer
        self.nixosModules.cachix
        self.nixosModules.sops
        self.nixosModules.extras
        self.nixosModules.tailscale
        self.nixosModules.docker
        self.nixosModules.qemu

        # per-user hjem profiles (kdj = full, yjh = restricted guest)
        self.nixosModules.userKdj
        self.nixosModules.userYjh
        self.nixosModules.guestWipe

        inputs.disko.nixosModules.disko
        self.diskoConfigurations.uriel
      ]
      # toggle heavy/optional modules by renaming `X.nix` -> `_X.nix` to skip.
      ++ lib.optional (self ? nixosModules.lanzaboote) self.nixosModules.lanzaboote;

      # extras is now option-driven (never renamed): heavy/optional components
      # stay OFF unless flipped here. See features/extras.nix.
      extras = {
        waydroid.enable = false;
      };

      # desktop configurations: flip ON whichever compositors you want available in SDDM.
      # Both can be ON simultaneously — the session picker shows all enabled.
      desktop.configNiri.enable = true;

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.hostName = "uriel";
      networking.networkmanager.enable = true;

      # Per-user passwords live in the user modules (kdj.nix / yjh.nix) —
      # they're the owner of each account. Same mechanism as before: a file in
      # /persist/passwords/<user> re-applied on every boot via update-users-groups.

      # sops: which secrets this host decrypts. Gated per-host here (see
      # nixos/features/sops.nix for the shared key plumbing). uriel.yaml is
      # encrypted for [kdj, uriel] — see .sops.yaml.
      sops.defaultSopsFile = ./../../../secrets/uriel.yaml;
      sops.secrets.github_ssh_private_key = {
        # keyed to kdj so the user's git can read it (default root:root)
        path = "/home/kdj/.ssh/id_ed25519";
        owner = "kdj";
        group = "users";
        mode = "0600";
      };
      sops.secrets.github_ssh_pubkey = {
        # pubkey is public — readable by any user in the `keys` group
        # (dir /run/secrets is root:keys).
        path = "/home/kdj/.ssh/id_ed25519.pub";
        owner = "kdj";
        group = "users";
        mode = "0444";
      };
      sops.secrets.codeberg_ssh_private_key = {
        path = "/home/kdj/.ssh/id_ed25519_cb";
        owner = "kdj";
        group = "users";
        mode = "0600";
      };
      sops.secrets.codeberg_ssh_pubkey = {
        path = "/home/kdj/.ssh/id_ed25519_cb.pub";
        owner = "kdj";
        group = "users";
        mode = "0444";
      };
      sops.secrets.tangled_ssh_private_key = {
        path = "/home/kdj/.ssh/id_ed25519_tangled";
        owner = "kdj";
        group = "users";
        mode = "0600";
      };
      sops.secrets.tangled_ssh_pubkey = {
        path = "/home/kdj/.ssh/id_ed25519_tangled.pub";
        owner = "kdj";
        group = "users";
        mode = "0444";
      };

      system.stateVersion = "26.05";
    };
}
