{ inputs, ... }: {
  flake.nixosModules.qylock = { lib, ... }: {
    imports = [
      inputs.qylock.nixosModules.default
    ];

    # qylock theming for the SDDM login screen + the quickshell `qylock-lock`
    # session locker (both use the same theme; sddm/quickshell enable are
    # upstream's recommended defaults). Toggle off by renaming this file to
    # _qylock.nix → SDDM falls back to its default breeze greeter and the
    # qylock-lock keybind silently does nothing. Pick a theme per desktop via
    # the `theme` option (any directory name under themes/ in the upstream
    # repo, e.g. "star-rail", "nier-automata", "genshin", "pixel-cyberpunk",
    # ...).
    programs.qylock = {
      enable = true;
      theme = lib.mkDefault "star-rail";
      # sddm.enable = true;        # installs theme + sets it active (default)
      # quickshell.enable = true;  # adds `qylock-lock` to PATH (default)
    };
  };
}
