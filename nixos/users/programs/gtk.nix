{ name }:
{ pkgs, ... }:
{
  packages = with pkgs; [
    adwaita-icon-theme
  ];

  xdg.config.files = {
    "gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-theme-name=Adwaita-dark
      gtk-icon-theme-name=Adwaita
      gtk-cursor-theme-name=Bibata-Modern-Ice
      gtk-cursor-theme-size=28
    '';
    "gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-theme-name=Adwaita-dark
      gtk-icon-theme-name=Adwaita
      gtk-cursor-theme-name=Bibata-Modern-Ice
      gtk-cursor-theme-size=28
    '';
  };
  files = {
    ".icons/default/index.theme".text = ''
      [Icon Theme]
      Inherits=Bibata-Modern-Ice
    '';
    ".local/share/icons/default/index.theme".text = ''
      [Icon Theme]
      Inherits=Bibata-Modern-Ice
    '';
  };
}
