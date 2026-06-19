{ inputs, self, lib, ... }: {
  flake.wrappers.tuigreet = {
    pkgs,
    wlib,
    config,
    ...
  }: {
    imports = [ wlib.modules.default ];

    package = inputs.tuigreet.packages.${pkgs.stdenv.hostPlatform.system}.tuigreet;

    constructFiles.tuigreetConfig = {
      relPath = "tuigreet-config.toml";
      content = ''
        [display]
        show_time = true
        time_format = "%H:%M"
        align_greeting = "center"
        issue = false

        [layout]
        width = 50
        window_padding = 2
        container_padding = 2
        prompt_padding = 1

        [layout.widgets]
        time_position = "top"
        status_position = "bottom"

        [user_menu]
        enabled = true
        min_uid = 1000

        [secret]
        mode = "characters"
        characters = "●"

        [theme]
        border = "${self.theme.base0D}"
        text = "${self.theme.base05}"
        time = "${self.theme.base0A}"
        container = "${self.theme.base00}"
        title = "${self.theme.base0C}"
        greet = "${self.theme.base0B}"
        prompt = "${self.theme.base0D}"
        input = "${self.theme.base05}"
        action = "${self.theme.base0E}"
        button = "${self.theme.base08}"
      '';
    };

    flags."--config" = config.constructFiles.tuigreetConfig.path;
  };
}
