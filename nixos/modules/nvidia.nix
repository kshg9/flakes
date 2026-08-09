# NVIDIA GPU driver stack. Imported unconditionally by extras.nix; the
# `extras.nvidia.enable` option (defined in extras.nix, master-ANDed there) is
# the sole gate — this module only reads `config.extras.nvidia.enable`.
{ self, ... }: {
  flake.nixosModules.nvidia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.extras.nvidia.enable {
      services.xserver.videoDrivers = [ "nvidia" ];

      boot.initrd.kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_drm"
        "nvidia_uvm"
      ];

      nixpkgs.config.cudaSupport = true;

      hardware.nvidia = {
        open = false;
        modesetting.enable = true;

        powerManagement = {
          enable = true;
          finegrained = false;
        };

        nvidiaPersistenced = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
          libva-vdpau-driver
        ];
        extraPackages32 = with pkgs; [
          driversi686Linux.libva-vdpau-driver
        ];
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        NVD_BACKEND = "direct";
      };
    };
}