{ name }:
{ pkgs, ... }:
{
  packages = [ pkgs.mpv ];
  xdg.config.files = {
    "mpv/mpv.conf".source = ../files/mpv.conf;
    "mpv/input.conf".source = ../files/input.conf;
    "mpv/shaders".source = pkgs.fetchzip {
      url = "https://github.com/bloc97/Anime4K/releases/download/v4.0.1/Anime4K_v4.0.zip";
      sha256 = "18x5q7zvkf5l0b2phh70ky6m99fx1pi6mhza4041b5hml7w987pl";
      stripRoot = false;
    };
  };
}
