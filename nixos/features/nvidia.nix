{ self, ... }: {
  flake.nixosModules.nvidia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      nix.settings = {
        substituters = [
          "https://cache.nixos-cuda.org"
        ];
        trusted-public-keys = [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];
      };

      services.xserver.videoDrivers = [ "nvidia" ];

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
        NIXOS_OZONE_WL = "1";
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        NVD_BACKEND = "direct";
      };
    };
}
