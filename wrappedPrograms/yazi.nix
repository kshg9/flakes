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
                command yazi $argv --cwd-file="$tmp"
                if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
                    builtin cd -- "$cwd"
                end
                command rm -f -- "$tmp"
            end
          '';
        };
      };
    };
}
