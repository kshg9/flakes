{ ... }: {
  flake.nixosModules.docker = { pkgs, ... }: {
    virtualisation.docker.enable = true;
    users.groups.docker.members = [ "kdj" "yjh" ];
    environment.systemPackages = with pkgs; [ docker-compose ];
  };
}
