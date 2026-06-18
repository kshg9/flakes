{
  self,
  lib,
  ...
}: {
  flake.wrappers.kitty = {
    wlib,
    config,
    ...
  }: {
    imports = [ wlib.wrapperModules.kitty ];

    options.shell = lib.mkOption {
      type = lib.types.str;
      default = "";
    };

    config = {
      settings = {
        term = "xterm-kitty";

        font_family = "JetBrainsMono Nerd Font";
        bold_font = "auto";
        italic_font = "auto";
        bold_italic_font = "auto";
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
        cursor = self.theme.base0B;

        scrollback_lines = 10000;
        scrollback_pager = "nvim -c 'setlocal buftype=nofile nonumber norelativenumber' -";

        tab_bar_edge = "bottom";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        tab_bar_min_tabs = 1;
        tab_bar_background = self.theme.base00;

        tab_title_template = " {index}: {title} ";

        active_tab_foreground = self.theme.base00;
        active_tab_background = self.theme.base0A;
        active_tab_font_style = "bold";

        inactive_tab_foreground = self.theme.base04;
        inactive_tab_background = self.theme.base01;
        inactive_tab_font_style = "normal";

        background_opacity = "0.95";
        background = self.theme.base00;
        foreground = self.theme.base05;
        selection_foreground = self.theme.base06;
        selection_background = self.theme.base03;

        color0 = self.theme.base00;
        color8 = self.theme.base02;
        color1 = self.theme.base08;
        color9 = self.theme.base08;
        color2 = self.theme.base0B;
        color10 = self.theme.base0B;
        color3 = self.theme.base0A;
        color11 = self.theme.base0A;
        color4 = self.theme.base0D;
        color12 = self.theme.base0D;
        color5 = self.theme.base0E;
        color13 = self.theme.base0E;
        color6 = self.theme.base0C;
        color14 = self.theme.base0C;
        color7 = self.theme.base03;
        color15 = self.theme.base04;

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
