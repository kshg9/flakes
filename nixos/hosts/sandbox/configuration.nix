{
  inputs,
  self,
  ...
}:
{
  flake.nixosConfigurations.sandbox = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostSandbox
    ];
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
      imports =
        [
          self.nixosModules.base
          self.nixosModules.general
          self.nixosModules.desktop
          self.nixosModules.nix
          self.nixosModules.keyd
          # qemu-vm.nix declares virtualisation.memorySize/diskSize + system.build.vm
          # at base level. This host is a VM, so applying it unconditionally is fine.
          (modulesPath + "/virtualisation/qemu-vm.nix")
        ]
        # qylock star-rail SDDM/login theme + quickshell lockscreen (rename
        # qylock.nix -> _qylock.nix to fall back to the plain breeze greeter).
        # Different theme than uriel — per-desktop theming demo.
        ++ lib.optional (self ? nixosModules.qylock) self.nixosModules.qylock;

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;

      networking.hostName = "sandbox";
      networking.networkmanager.enable = true;

      # Disposable VM → known dev password. Password: `vm`.
      users.users.${config.preferences.user.name}.initialHashedPassword =
        "$6$XjYPyh/Kt30OoNKn$EeNci/RYnQQKgkGilJwPkh5oreAhiu16HpH2LAsAb54NrE85O5rOowZ5HQQyKUX7dTIsA5q3K7eOAtCfQtqc5/";

      # Per-desktop qylock theme: sandbox tries a different one than uriel.
      programs.qylock.theme = "nier-automata";

      nixpkgs.config.allowUnfree = true;

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
