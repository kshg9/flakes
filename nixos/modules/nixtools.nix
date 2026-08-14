{ inputs, ... }: {
  # Nix developer tooling / daemon settings (renamed from the old `nix.nix`).
  flake.nixosModules.nixTools = { pkgs, ... }: {
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
        "cgroups"
      ];
      use-cgroups = true;
    use-xdg-base-directories = true;
    http-connections = 20;
    show-trace = true;
    builders-use-substitutes = true;
    };

    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [ 
        zlib
        openssl
        stdenv.cc.cc.lib
       ];
    };

    programs.appimage = {
      enable = true;
      binfmt = true;
    };

    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep 10 --keep-since 3d";
      };
      flake = "/home/kdj/flakes";
    };
  };
}
