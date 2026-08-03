{
  flake.wrappers.niri = {
    wlib,
    pkgs,
    config,
    ...
  }: {
    imports = [ wlib.wrapperModules.niri ];

    config.settings = {
      prefer-no-csd = _: { };

      # capitaine-cursors (also set on the SDDM greeter in desktop.nix).
      # xcursor-theme/size are applied to Xwayland apps too via XCURSOR_*.
      cursor = {
        xcursor-theme = "capitaine-cursors";
        xcursor-size = 24;
      };

      input = {
        keyboard = {
          xkb.layout = "us";
          repeat-rate = 40;
          repeat-delay = 250;
        };
        touchpad = {
          tap = _: { };
          natural-scroll = _: { };
          dwt = _: { };
        };
        mouse.accel-profile = "flat";
      };

      spawn-at-startup = [ [ "noctalia" ] [ "vicinae" "server" ] ];

      binds = {
        "Mod+Space".spawn-sh = "vicinae toggle";
        "Mod+Return".spawn = "kitty";
        "Mod+Q".close-window = _: { };
        "Mod+F".maximize-column = _: { };
        "Mod+Shift+F".fullscreen-window = _: { };

        "Mod+P" = _: {
          props.repeat = false;
          content.spawn = [ "vicinae" "vicinae://launch/clipboard/history" ];
        };

        # Noctalia IPC (bound away from vicinae's Mod+Space/Mod+P).
        "Mod+Shift+Space".spawn-sh = "noctalia msg panel-toggle launcher";
        "Mod+S".spawn-sh = "noctalia msg panel-toggle control-center";
        "Mod+Comma".spawn-sh = "noctalia msg settings-toggle";
        "Alt+Tab".spawn-sh = "noctalia msg window-switcher";

        "Mod+H".focus-column-left = _: { };
        "Mod+L".focus-column-right = _: { };
        "Mod+K".focus-window-up = _: { };
        "Mod+J".focus-window-down = _: { };

        "Mod+Shift+H".move-column-left = _: { };
        "Mod+Shift+L".move-column-right = _: { };
        "Mod+Shift+K".move-window-up = _: { };
        "Mod+Shift+J".move-window-down = _: { };

        "Mod+U".focus-workspace-down = _: { };
        "Mod+I".focus-workspace-up = _: { };
        "Mod+Ctrl+U".move-column-to-workspace-down = _: { };
        "Mod+Ctrl+I".move-column-to-workspace-up = _: { };

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

        "Print".screenshot = _: { };
        "Ctrl+Print".screenshot-screen = _: { };
        "Alt+Print".screenshot-window = _: { };

        "Mod+Shift+Slash".show-hotkey-overlay = _: { };

        "Mod+Escape" = _: {
          props.allow-inhibiting = false;
          content.toggle-keyboard-shortcuts-inhibit = _: { };
        };

        "Mod+Shift+E".quit = _: { };

        # Lock screen (qylock quickshell lockscreen; no-op if qylock toggled off).
        "Mod+Shift+Q".spawn = "qylock-lock";

        "XF86AudioRaiseVolume".spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume".spawn-sh = "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioMute".spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

        "XF86MonBrightnessUp" = _: {
          props.allow-when-locked = true;
          content.spawn = [ "brightnessctl" "set" "+5%" ];
        };
        "XF86MonBrightnessDown" = _: {
          props.allow-when-locked = true;
          content.spawn = [ "brightnessctl" "set" "5%-" ];
        };
      };

      layout = {
        gaps = 8;
        focus-ring = {
          width = 3;
          active-color = "#f5c2e7";
        };
        shadow = {
          on = _: { };
          softness = 30;
          spread = 6;
          offset = _: {
            props = {
              x = 0;
              y = 4;
            };
          };
          color = "#0008";
        };
      };

      hotkey-overlay = {
        # Uncomment to disable the startup hotkey popup once you know them.
        # skip-at-startup = _: { };
      };

      # Uncomment once you're comfortable with the path.
      # "screenshot-path" = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      # Noctalia v5 shell — rounded corners everywhere + its settings window floats.
      window-rules = [
        {
          geometry-corner-radius = 20;
          clip-to-geometry = true;
        }
        {
          matches = [ { app-id = "^dev\\.noctalia\\.Noctalia$"; } ];
          open-floating = true;
          default-column-width = { fixed = 1080; };
          default-window-height = { fixed = 920; };
        }
        {
          matches = [ { app-id = "firefox$"; title = "^Picture-in-Picture$"; } ];
          open-floating = true;
        }
        # Block password managers from screen capture.
        # {
        #   matches = [ { app-id = "^org\\.keepassxc\\.KeePassXC$"; } ];
        #   block-out-from = "screen-capture";
        # }
        # {
        #   matches = [ { app-id = "^org\\.gnome\\.World\\.Secrets$"; } ];
        #   block-out-from = "screen-capture";
        # }
      ];

      # Noctalia IPC needs notification actions + window activation to work.
      debug = {
        honor-xdg-activation-with-invalid-serial = _: { };
      };

      workspaces = {
        "w0" = { };
        "w1" = { };
      };
    };
  };
}
