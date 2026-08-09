{
  inputs,
  self,
  config,
  ...
}:
{
  flake.nixosConfigurations.sandbox = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostSandbox
    ];
    # ctp = resolved catppuccin palette — a flake-level value injected into the
    # NixOS module system (NOT reachable via config.flake from NixOS modules).
    specialArgs = {
      ctp = config.flake.ctpPalette;
    };
  };

  flake.nixosModules.hostSandbox =
    {
      config,
      pkgs,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        self.nixosModules.base
        self.nixosModules.general
        self.nixosModules.desktop
        self.nixosModules.nixTools
        self.nixosModules.keyd
        self.nixosModules.cachix
        self.nixosModules.extras
        # sops boot-key plumbing (no secrets declared yet — sandbox's boot key
        # doesn't exist until nixos/features/secrets/sandbox.yaml is created;
        # see KB/sops.md "two-host model").
        self.nixosModules.sops
        # per-user hjem profile (ephemeral test user biyoo — see nixos/users/biyoo.nix)
        self.nixosModules.userBiyoo
        # qemu-vm.nix declares virtualisation.memorySize/diskSize + system.build.vm
        # at base level. This host is a VM, so applying it unconditionally is fine.
        (modulesPath + "/virtualisation/qemu-vm.nix")
      ];

      # When sandbox has a boot key + sandbox.yaml, declare its secrets here:
      #   sops.defaultSopsFile = ./../../features/secrets/sandbox.yaml;
      #   sops.secrets.github_ssh_private_key = { owner = "biyoo"; group = "users"; mode = "0600"; };

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.hostName = "sandbox";
      networking.networkmanager.enable = true;

      nixpkgs.config.allowUnfree = true;

      # extras is OFF on sandbox by default — machine-level heavy/configurable
      # modules only (nvidia, vicinae, …; see KB/module-toggle.md). Per-user apps
      # are managed in each user's hjem profile instead.
      extras.enable = false;

      system.stateVersion = "26.05";

      # Plain build-vm test box — no disko, no LUKS, no impermanence. A clean,
      # disposable OS for experimenting with declarative apps (hyprland, niri,
      # lxqt, home-manager/hjem variants, etc.). Nothing here touches
      # uriel's disk stack.
      virtualisation.memorySize = 4096;
      virtualisation.diskSize = 40960;
      # niri hard-requires OpenGL (EGL_EXT_device_drm). The default std VGA is
      # a plain framebuffer — no GL — so niri would blackscreen after login.
      # Pass a virgl (GL) virtio GPU instead; our qemu is built with virglrenderer.
      virtualisation.qemu.options = [
        "-device virtio-vga-gl"
        "-display gtk,gl=on"
      ];
      # Headless (serial on stdout) for scripted runs:
      # virtualisation.graphics = false;
      # boot.kernelParams = [ "console=ttyS0,115200n8" ];
    };
}
