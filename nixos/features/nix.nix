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
    };

    programs.nix-ld.enable = true;

    programs.nh = {
      enable = true;
      clean.enable = true;
      flake = "/etc/nixos/nyx";
    };

    environment.systemPackages = with pkgs; [
      nixd
      statix
      nixfmt
      nix-diff
    ];
  };
}
