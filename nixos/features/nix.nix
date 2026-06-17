{ inputs, ... }: {
  flake.nixosModules.nix = { pkgs, ... }: {
    imports = [
      inputs.nix-index-database.nixosModules.nix-index
    ];

    programs.nix-index-database.comma.enable = true;

    programs.direnv = {
      enable = true;
      silent = true;
      loadInNixShell = true;
      nix-direnv.enable = true;
    };

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      substituters = [ "https://nix-community.cachix.org" ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    programs.nix-ld.enable = true;

    programs.nh = {
      enable = true;
      clean.enable = true;
      flake = "/etc/nixos/zinx";
    };

    environment.systemPackages = with pkgs; [
      nixd
      statix
      nixfmt
      nix-diff
    ];
  };
}
