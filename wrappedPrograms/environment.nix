{
  lib,
  self,
  ...
}: {
  flake.wrappers.environment = { pkgs, ... }: let
    selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}";
  in {
    imports = [ self.wrapperModules.fish ];
    binName = "fish";
    runtimePkgs = [
      pkgs.git
      pkgs.eza
      pkgs.fd
      pkgs.ripgrep
      pkgs.fzf
      pkgs.htop
      pkgs.zoxide
      pkgs.just
      pkgs.wl-clipboard
      selfpkgs.neovim
      selfpkgs.yazi
      selfpkgs.qalc
    ];
    plugins = [
      { src = selfpkgs.yazi; }
      { src = pkgs.fishPlugins.hydro; }
    ];
    env.EDITOR = lib.getExe selfpkgs.neovim;
  };

  flake.wrappers.terminal = { pkgs, ... }: let
    selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}";
  in {
    imports = [ self.wrapperModules.kitty ];
    shell = lib.getExe selfpkgs.environment;
  };

}
