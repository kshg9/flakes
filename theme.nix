let
  theme = {
    base00 = "#1f1f28"; # sumiInk0 / bg
    base01 = "#2a2a37"; # sumiInk1b / darker
    base02 = "#223249"; # waveBlue1 / selection overlay
    base03 = "#363646"; # sumiInk4 / selection bg
    base04 = "#54546d"; # fujiGray / muted
    base05 = "#dcd7ba"; # fujiWhite / fg — warm cream
    base06 = "#e6c384"; # carpYellow / bright fg — golden
    base07 = "#f2ecbc"; # oldWhite / light fg
    base08 = "#e46876"; # sakuraPink / red — warm
    base09 = "#ffa066"; # peachRed / orange
    base0A = "#e6c384"; # carpYellow / yellow — golden
    base0B = "#98bb6c"; # springGreen / green — warmer
    base0C = "#7aa89f"; # waveAqua1 / cyan-teal
    base0D = "#7e9cd8"; # crystalBlue / blue — violet-warm
    base0E = "#957fb8"; # springViolet1 / magenta
    base0F = "#ffa066"; # peachRed / orange2
  };

  stripHash =
    str:
    if builtins.substring 0 1 str == "#" then
      builtins.substring 1 (builtins.stringLength str - 1) str
    else
      str;

  themeNoHash = builtins.mapAttrs (_: v: stripHash v) theme;
in
{
  flake = {
    inherit theme themeNoHash;
  };
}
