{ self, lib, ... }: {
  flake.wrappers.yazi =
    {
      pkgs,
      wlib,
      config,
      ...
    }:
    {
      imports = [ wlib.wrapperModules.yazi ];

      settings.yazi = {
        mgr = {
          "sort-by" = "alphabetical";
          "sort-dir-first" = true;
          linemode = "size";
        };
        plugin = {
          "prepend-fetchers" = [
            {
              url = "*";
              run = "git";
              group = "git";
            }
            {
              url = "*/";
              run = "git";
              group = "git";
            }
          ];
        };
      };

      settings.keymap = {
        mgr = {
          "prepend-keymap" = [
            {
              on = [ "Y" ];
              run = "plugin wl-clipboard";
              desc = "Copy to clipboard (Wayland)";
            }
            {
              on = [
                "c"
                "d"
              ];
              run = "shell -- kitten dnd %c";
              desc = "Kitty drag-n-drop selected file(s)";
            }
          ];
        };
      };

      plugins = with pkgs.yaziPlugins; {
        git = git;
        wl-clipboard = wl-clipboard;
      };

      constructFiles = {
        fishYFunction = {
          relPath = "share/fish/vendor_functions.d/y.fish";
          content = ''
            function y
                set tmp (mktemp -t "yazi-cwd.XXXXXX")
                yazi --cwd-file="$tmp"
                if set cwd (command cat -- "$tmp"); and test -n "$cwd"; and test "$cwd" != "$PWD"
                    builtin cd -- "$cwd"
                end
                rm -f -- "$tmp"
            end
          '';
        };
      };
    };
}
