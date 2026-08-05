{ self, ... }: {
  flake.wrappers.fish = {
    wlib,
    pkgs,
    lib,
    ...
  }:
  let
    selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}";
  in {
    imports = [ wlib.wrapperModules.fish ];

    configFile.content = ''
      ${lib.getExe pkgs.zoxide} init fish | source
      ${lib.getExe selfpkgs.starship} init fish | source

      # Dim the autosuggestions (edge/suggestion) so they read as a ghost of
      # what's already typed instead of matching the live foreground. Catppuccin
      # mocha, dimmed from the default foreground #cdd6f4.
      set -g fish_color_autosuggestion '#6c7086'
      set -g fish_color_edge '#6c7086'
      set -g fish_color_selection --background=#585b70

      function y
          set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
          command yazi $argv --cwd-file="$tmp"
          set -l code $status
          if test -s "$tmp"
              set -l cwd (string trim < "$tmp")
              if test -n "$cwd"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
                  builtin cd -- "$cwd"
              end
          end
          command rm -f -- "$tmp"
          return $code
      end
    '';
  };
}
