{
  lib,
  ...
}: {
  flake.wrappers.kitty = {
    wlib,
    config,
    ...
  }: let
    theme = {
      base00 = "#1f1f28";
      base01 = "#2a2a37";
      base02 = "#223249";
      base03 = "#363646";
      base04 = "#54546d";
      base05 = "#dcd7ba";
      base06 = "#e6c384";
      base08 = "#e46876";
      base0A = "#e6c384";
      base0B = "#98bb6c";
      base0C = "#7aa89f";
      base0D = "#7e9cd8";
      base0E = "#957fb8";
    };
  in {
    imports = [ wlib.wrapperModules.kitty ];

    options.shell = lib.mkOption {
      type = lib.types.str;
      default = "";
    };

    config = {
      settings = {
        term = "xterm-kitty";

        font_family = "CommitMono Nerd Font Mono";
        bold_font = "CommitMono Nerd Font Mono";
        italic_font = "CommitMono Nerd Font Mono";
        bold_italic_font = "CommitMono Nerd Font Mono";
        font_size = 13;
        disable_ligatures = "never";

        enable_audio_bell = "no";
        confirm_os_window_close = 0;

        allow_remote_control = "yes";
        listen_on = "unix:/tmp/kitty";
        shell_integration = "enabled";

        hide_window_decorations = "yes";
        window_padding_width = 10;

        cursor_shape = "block";
        cursor_blink_interval = 0;
        cursor_text_color = "background";
        cursor = theme.base0B;

        scrollback_lines = 10000;
        scrollback_pager = "nvim -c 'setlocal buftype=nofile nonumber norelativenumber' -";

        tab_bar_edge = "bottom";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        tab_bar_min_tabs = 1;
        tab_bar_background = theme.base00;

        tab_title_template = " {index}: {title} ";

        active_tab_foreground = theme.base00;
        active_tab_background = theme.base0A;
        active_tab_font_style = "bold";

        inactive_tab_foreground = theme.base04;
        inactive_tab_background = theme.base01;
        inactive_tab_font_style = "normal";

        background_opacity = "0.95";
        background = theme.base00;
        foreground = theme.base05;
        selection_foreground = theme.base06;
        selection_background = theme.base03;

        color0 = theme.base00;
        color8 = theme.base02;
        color1 = theme.base08;
        color9 = theme.base08;
        color2 = theme.base0B;
        color10 = theme.base0B;
        color3 = theme.base0A;
        color11 = theme.base0A;
        color4 = theme.base0D;
        color12 = theme.base0D;
        color5 = theme.base0E;
        color13 = theme.base0E;
        color6 = theme.base0C;
        color14 = theme.base0C;
        color7 = theme.base03;
        color15 = theme.base04;

        repaint_delay = 8;
        input_delay = 1;
        sync_to_monitor = "yes";

        enabled_layouts = "splits,stack,fat,tall,grid";
      } // lib.optionalAttrs (config.shell != "") { shell = config.shell; };

      keybindings = {
        # Clipboard
        "ctrl+shift+c" = "copy_to_clipboard";
        "ctrl+shift+v" = "paste_from_clipboard";

        # Font size
        "ctrl+shift+equal" = "change_font_size all +1.0";
        "ctrl+shift+minus" = "change_font_size all -1.0";
        "ctrl+shift+backspace" = "change_font_size all 0";

        # Splits
        "ctrl+shift+enter" = "launch --location=hsplit --cwd=current";
        "ctrl+shift+backslash" = "launch --location=vsplit --cwd=current";

        # Navigate panes
        "ctrl+shift+h" = "neighboring_window left";
        "ctrl+shift+l" = "neighboring_window right";
        "ctrl+shift+k" = "neighboring_window up";
        "ctrl+shift+j" = "neighboring_window down";

        # Move panes
        "ctrl+shift+alt+h" = "move_window left";
        "ctrl+shift+alt+l" = "move_window right";
        "ctrl+shift+alt+k" = "move_window top";
        "ctrl+shift+alt+j" = "move_window bottom";

        # Close pane
        "ctrl+shift+w" = "close_window";

        # Layouts
        "ctrl+shift+e" = "next_layout";
        "ctrl+shift+z" = "toggle_layout stack";

        # Tabs
        "ctrl+shift+t" = "new_tab_with_cwd";
        "ctrl+shift+q" = "close_tab";
        "ctrl+shift+." = "next_tab";
        "ctrl+shift+," = "previous_tab";
        "ctrl+shift+1" = "goto_tab 1";
        "ctrl+shift+2" = "goto_tab 2";
        "ctrl+shift+3" = "goto_tab 3";
        "ctrl+shift+4" = "goto_tab 4";
        "ctrl+shift+5" = "goto_tab 5";

        # Scrollback
        "ctrl+shift+g" = "show_scrollback";
        "ctrl+shift+page_up" = "scroll_page_up";
        "ctrl+shift+page_down" = "scroll_page_down";
        "ctrl+shift+home" = "scroll_home";
        "ctrl+shift+end" = "scroll_end";

        # Misc
        "ctrl+shift+u" = "kitten unicode_input";
        "ctrl+shift+o" = "open_url_with_hints";
      };
    };
  };
}
