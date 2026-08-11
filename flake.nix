{
  inputs = {
    # Main nixpkgs: nixos-unstable (the default, its latest tip is always
    # hydrated on the binary cache → cached-latest binaries).
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Stable nixpkgs, deliberately pinned to the STABLE branch (nixos-26.05),
    # for base-system stability. Can supply package pins that must not drift.
    # NOTE: using this as the base flips the whole OS closure to a different rev
    # → one-time big re-hydration (see KB/gotchas.md §10).
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    # flake, module imports are automatic via custom function.
    flake-parts.url = "github:hercules-ci/flake-parts";
    impermanence.url = "github:nix-community/impermanence";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative secrets; age keys decrypted via the persisted ssh host key.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae.url = "github:vicinaehq/vicinae";
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    # UEFI Secure Boot via Lanzaboote (replaces systemd-boot signing).
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  # Import all .nix files from current directory except flake.nix recursively
  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
      inherit (lib.fileset) toList fileFilter;

      isNixModule = file: file.hasExt "nix" && file.name != "flake.nix" && !lib.hasPrefix "_" file.name;

      importTree = path: toList (fileFilter isNixModule path);

      mkFlake = inputs.flake-parts.lib.mkFlake { inherit inputs; };
    in
    mkFlake {
      imports = importTree ./nixos/hosts
        ++ importTree ./nixos/modules
        ++ importTree ./nixos/base
        ++ importTree ./packages
        ++ [
          ./nixos/users/base.nix
          ./nixos/users/kdj.nix
          ./nixos/users/yjh.nix
          ./nixos/users/biyoo.nix
        ]
        # declares `flake.diskoConfigurations` so multiple hosts can define it
        ++ [ inputs.disko.flakeModules.default ];
      systems = [ "x86_64-linux" ];
    };
}
