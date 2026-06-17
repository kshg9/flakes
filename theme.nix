let
  theme = {
    base00 = "#0d0c0c"; # dragonBlack1 / bg
    base01 = "#1f1f28"; # dark
    base02 = "#2a2a37"; # darkish
    base03 = "#363646"; # selection bg
    base04 = "#54546d"; # muted
    base05 = "#c5c9c5"; # dragonWhite / fg
    base06 = "#dcd7ba"; # fujiWhite
    base07 = "#f2ecbc"; # oldWhite / light fg
    base08 = "#c4746e"; # dragonRed
    base09 = "#b6927b"; # dragonOrange
    base0A = "#c4b28f"; # dragonYellow
    base0B = "#87a987"; # dragonGreen
    base0C = "#8ea4a2"; # dragonAqua
    base0D = "#8ba4b0"; # dragonBlue
    base0E = "#a292a3"; # dragonPink
    base0F = "#b6927b"; # dragonOrange
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
