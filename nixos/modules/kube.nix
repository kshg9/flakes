{ lib, config, pkgs, ... }: {
  flake.nixosModules.kube = { lib, config, pkgs, ... }: {
    config = lib.mkIf config.extras.kube.enable {
      environment.systemPackages = with pkgs; [
        kubectl
        k3d
        kubernetes-helm
      ];
    };
  };
}
