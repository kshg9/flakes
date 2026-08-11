{
  inputs,
  self,
  config,
  ...
}:
{
  flake.nixosConfigurations.sandbox = config.flake.nebula.mkHost {
    module = self.nixosModules.hostSandbox;
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
        self.nixosModules.nixpkgsConfig
        self.nixosModules.general

        self.nixosModules.nixTools
        self.nixosModules.keyd
        self.nixosModules.cachix
        self.nixosModules.extras
        # per-user hjem profile (ephemeral test user biyoo — see nixos/users/biyoo.nix)
        self.nixosModules.userBiyoo
        # qemu-vm.nix declares virtualisation.memorySize/diskSize + system.build.vm
        # at base level. This host is a VM, so applying it unconditionally is fine.
        (modulesPath + "/virtualisation/qemu-vm.nix")
      ];

      # -- Sandbox Minimal GUI --
      # Inlined here instead of importing `self.nixosModules.desktop` (which is tuned
      # for the primary host) so you can easily rip it out or hack on it for tests.
      services.xserver.enable = true;
      services.displayManager.sddm.enable = true;
      services.displayManager.sddm.wayland.enable = true;
      programs.labwc.enable = true;
      fonts.packages = with pkgs; [ ubuntu-sans nerd-fonts.commit-mono ];
      # -------------------------

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.hostName = "sandbox";
      networking.networkmanager.enable = true;

      # extras is OFF on sandbox by default — machine-level heavy/configurable
      # modules only (nvidia, vicinae, …; see KB/module-toggle.md). Per-user apps
      # are managed in each user's hjem profile instead.
      
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
      # grab-on-hover: the host runs niri (Wayland), whose window input-grab is
      # flaky — without it keypresses (e.g. Meta+T) are eaten by the host and
      # never reach the guest. This captures keyboard+pointer once the mouse is
      # over the VM window.
      virtualisation.qemu.options = [
        "-device virtio-vga-gl"
        "-display gtk,gl=on,grab-on-hover=on"
      ];
      # Headless (serial on stdout) for scripted runs:
      # virtualisation.graphics = false;
      # boot.kernelParams = [ "console=ttyS0,115200n8" ];

      # virtiofs: share the host's Downloads folder into the VM at /mnt/host
      # (file transfer in/out of the sandbox).
      virtualisation.sharedDirectories = {
        host-share = {
          source = "/home/kdj/Downloads";
          target = "/mnt/host";
        };
      };
    };
}
