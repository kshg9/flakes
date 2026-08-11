{ name }:
{ pkgs, ... }:
{
  packages = with pkgs; [
    playerctl
    brightnessctl
    bibata-cursors
    kitty
    yazi
    git
    difftastic
    eza
    fd
    bat
    magika
    ripgrep
    fzf
    htop
    zoxide
    just
    wl-clipboard
    helix
    libqalculate
    starship
    mcfly
    wlsunset
    nautilus
  ];
  
  xdg.config.files = {
    "kitty/kitty.conf".source = ../files/kitty/kitty.conf;
    "kitty/colors.conf".source = ../files/kitty/colors.conf;

    "yazi/yazi.toml".source = ../files/yazi/yazi.toml;
    "yazi/init.lua".source = ../files/yazi/init.lua;
    "yazi/plugins/full-border.yazi".source = "${pkgs.yaziPlugins.full-border}";

    "starship.toml".source = ../files/starship/starship.toml;

    "fish/config.fish".source = ../files/fish/config.fish;
  };
}
