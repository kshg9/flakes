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

    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae.url = "github:vicinaehq/vicinae";

    # Noctalia v5 desktop shell. Pin the `cachix` branch (latest cached commit)
    # so prebuilt binaries from noctalia.cachix.org are used. Deliberately does
    # NOT follow nixpkgs — a follows would change the derivation hash and miss
    # the cache.
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };

    # UEFI Secure Boot via Lanzaboote (replaces systemd-boot signing).
    lanzaboote.url = "github:nix-community/lanzaboote";

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
      imports = importTree ./.
        # enables the `flake.wrappers.*` option used by wrappedPrograms/
        ++ [ inputs.wrapper-modules.flakeModules.wrappers ]
        # declares `flake.diskoConfigurations` so multiple hosts can define it
        ++ [ inputs.disko.flakeModules.default ];
      systems = [ "x86_64-linux" ];
    };
}
