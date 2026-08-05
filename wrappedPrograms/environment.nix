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
      pkgs.helix
      pkgs.yazi
      selfpkgs.qalc
    ];
    env.EDITOR = lib.getExe pkgs.helix;
  };
}
