{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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

    # SDDM + Quickshell lockscreen themes (Honkai: Star Rail, nier-automata, ...).
    # Module: qylock.nixosModules.default → `programs.qylock` (enable, theme,
    # sddm/quickshell toggles). Theme name = a dir under themes/ (see the module
    # for the full list). Repo is ~1.2GB but only fetched at build/install time
    # (the installer ISO already needs network for nixos-install), so it's a
    # plain input rather than vendored.
    qylock.url = "github:Darkkal44/qylock";
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
