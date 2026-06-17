{
  self,
  ...
}: {
  flake.wrappers.neovim = {
    wlib,
    pkgs,
    ...
  }: {
    imports = [ wlib.wrapperModules.neovim ];

    settings.config_directory = ./.;

    runtimePkgs = [
      pkgs.wl-clipboard
    ];
  };
}
