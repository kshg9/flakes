{
  self,
  lib,
  ...
}: {
  flake.wrappers.niri = {
    wlib,
    pkgs,
    config,
    ...
  }: {
    imports = [ wlib.wrapperModules.niri ];

    options.terminal = lib.mkOption {
      type = lib.types.str;
      default = "kitty";
    };

    config.settings = {
      prefer-no-csd = _: { };

      input = {
        keyboard = {
          xkb.layout = "us";
          repeat-rate = 40;
          repeat-delay = 250;
        };
        touchpad.natural-scroll = _: { };
        mouse.accel-profile = "flat";
      };

      binds = {
        "Mod+Space".spawn-sh = "vicinae toggle";
        "Mod+Return".spawn = config.terminal;
        "Mod+Q".close-window = _: { };
        "Mod+F".maximize-column = _: { };
        "Mod+Shift+F".fullscreen-window = _: { };

        "Mod+H".focus-column-left = _: { };
        "Mod+L".focus-column-right = _: { };
        "Mod+K".focus-window-up = _: { };
        "Mod+J".focus-window-down = _: { };

        "Mod+Shift+H".move-column-left = _: { };
        "Mod+Shift+L".move-column-right = _: { };
        "Mod+Shift+K".move-window-up = _: { };
        "Mod+Shift+J".move-window-down = _: { };

        "Mod+1".focus-workspace = "w0";
        "Mod+2".focus-workspace = "w1";
        "Mod+3".focus-workspace = "w2";
        "Mod+4".focus-workspace = "w3";
        "Mod+5".focus-workspace = "w4";

        "Mod+Shift+1".move-column-to-workspace = "w0";
        "Mod+Shift+2".move-column-to-workspace = "w1";
        "Mod+Shift+3".move-column-to-workspace = "w2";
        "Mod+Shift+4".move-column-to-workspace = "w3";
        "Mod+Shift+5".move-column-to-workspace = "w4";

        "Mod+Ctrl+H".set-column-width = "-5%";
        "Mod+Ctrl+L".set-column-width = "+5%";
        "Mod+Ctrl+J".set-window-height = "-5%";
        "Mod+Ctrl+K".set-window-height = "+5%";

        "XF86AudioRaiseVolume".spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume".spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioMute".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };

      layout = {
        gaps = 5;
        focus-ring = {
          width = 2;
          active-color = "${self.themeNoHash.base08}";
        };
      };

      workspaces = {
        "w0" = { layout.gaps = 5; };
        "w1" = { layout.gaps = 5; };
        "w2" = { layout.gaps = 5; };
        "w3" = { layout.gaps = 5; };
        "w4" = { layout.gaps = 5; };
      };
    };
  };
}