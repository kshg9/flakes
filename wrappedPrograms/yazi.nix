{ self, lib, ... }: {
  flake.wrappers.yazi =
    {
      pkgs,
      wlib,
      config,
      ...
    }:
    let
      plugins = with pkgs.yaziPlugins; {
        git = git;
        wl-clipboard = wl-clipboard;
      };

      makePlugin = name: pluginDrv: {
        content = "";
        relPath = "${config.binName}-config/plugins/${name}.yazi";
        builder = ''
          mkdir -p "$(dirname "$2")"
          ln -s "${pluginDrv}" "$2"
        '';
      };
    in
    {
      imports = [ wlib.wrapperModules.yazi ];

      settings.yazi = {
        enableFishIntegration = true;
        mgr = {
          sort_by = "alphabetical";
          sort_dir_first = true;
          linemode = "size";
        };
        plugin = {
          prepend_fetchers = [
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
          prepend_keymap = [
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

      constructFiles = lib.mapAttrs makePlugin plugins // {
        luaInit = {
          content = ''
            require("git"):setup()
            require("wl-clipboard"):setup()
          '';
          relPath = "${config.binName}-config/init.lua";
        };
      };
    };
}
