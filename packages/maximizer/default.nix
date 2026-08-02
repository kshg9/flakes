{
  perSystem =
    { pkgs, ... }:
    {
      # vendored from BirdeeHub/maximizer (tiny Xlib program) — finds a window by
      # title substring and resizes it to fill the screen. Used by the installer
      # ISO's fullscreen kitty session (no window manager needed).
      packages.maximizer = pkgs.stdenv.mkDerivation {
        pname = "maximizer";
        version = "0.1.0";
        src = ./maximizer.c;
        dontUnpack = true;
        buildInputs = [ pkgs.libx11 pkgs.libxrandr ];
        buildPhase = ''
          $CC -o maximizer $src -lX11 -lXrandr
        '';
        installPhase = ''
          mkdir -p $out/bin
          cp maximizer $out/bin/
        '';
      };
    };
}
