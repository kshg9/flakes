{ ... }: {
  flake.wrappers.fish = {
    wlib,
    pkgs,
    lib,
    ...
  }: {
    imports = [ wlib.wrapperModules.fish ];

    configFile.content = ''
      function fish_right_prompt
          set -l color_duration "#7aa89f"
          set -l color_reset (set_color normal)

          if test $CMD_DURATION -gt 0
              if test $CMD_DURATION -lt 1000
                  printf '%s%dms%s' (set_color $color_duration) $CMD_DURATION $color_reset
              else
                  set -l secs (math -s 2 "$CMD_DURATION / 1000")
                  printf '%s%ss%s' (set_color $color_duration) $secs $color_reset
              end
          end
      end

      set fish_color_autosuggestion "#54546d"

      ${lib.getExe pkgs.zoxide} init fish | source
    '';
  };
}
