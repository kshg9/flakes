# Catppuccin one.
#
#   config.flake.ctp            → { flavor = "mocha"; accent = "mauve"; }
#   config.flake.ctpPalette     → derived hex base/accent/surface
#
# A single top-level `flake` submodule lets every consumer (kitty, niri, hjem,
# accents, …) agree on one theme. Watch the shadowing footgun: inside
# `flake.wrappers.*` the inner `config` is the wrapper config, so capture
# `ctp`/`ctpPalette` in an outer `let` before entering the wrapper attr.
{
  lib,
  config,
  ...
}: let
  flavors = [ "frappe" "latte" "mocha" "macchiato" ];
  accents = [
    "rosewater" "flamingo" "pink" "mauve" "lavender" "blue" "sapphire" "sky"
    "teal" "green" "yellow" "peach" "maroon" "red"
  ];
in {
  options.flake = {
    ctp = lib.mkOption {
      type = lib.types.submodule {
        options = {
          flavor = lib.mkOption {
            type = lib.types.enum flavors;
            default = "mocha";
          };
          accent = lib.mkOption {
            type = lib.types.enum accents;
            default = "mauve";
          };
        };
      };
      default = { };
    };
    ctpPalette = lib.mkOption { type = lib.types.attrs; };
  };

  config.flake.ctpPalette =
    let
      c = config.flake.ctp;
      uv = {
        flavor_hex = {
          mocha = "#1e1e2e";
          macchiato = "#24273a";
          frappe = "#303446";
          latte = "#eff1f5";
        };
        accent_hex = {
          rosewater = "#f5e0dc";
          flamingo = "#f2cdcd";
          pink = "#f5c2e7";
          mauve = "#cba6f7";
          lavender = "#b4befe";
          blue = "#89b4fa";
          sapphire = "#74c7ec";
          sky = "#89dceb";
          teal = "#94e2d5";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          peach = "#fab387";
          maroon = "#eba0ac";
          red = "#f38ba8";
          gray = "#6c7086";
        };
      };
    in {
      base = uv.flavor_hex.${c.flavor};
      accent = uv.accent_hex.${c.accent};
      surface = "#313244";
      surfaceRGB = "#5b6078";
    };
}