{ name }:
{ pkgs, ... }:
{
  packages = with pkgs; [
    (vscode-with-extensions.override {
      vscode = vscodium-fhs;
      vscodeExtensions = with vscode-extensions; [
        jnoortheen.nix-ide
      ];
    })
  ];

  xdg.config.files = {
    "VSCodium/User/settings.json".source = ../files/vscodium/settings.json;
    "VSCodium/User/keybindings.json".source = ../files/vscodium/keybindings.json;
  };
}
