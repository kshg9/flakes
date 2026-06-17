{ self, ... }: {
  flake.wrappers.fish = {
    wlib,
    pkgs,
    lib,
    ...
  }: {
    imports = [ wlib.wrapperModules.fish ];

    configFile.content = ''
      function fish_prompt
          set -l color_user "${self.theme.base08}"
          set -l color_host "${self.theme.base0B}"
          set -l color_cwd "${self.theme.base0D}"
          set -l color_reset (set_color normal)

          printf '%s[%s%s%s@%s%s%s %s%s%s]%s $ ' \
              (set_color $color_user) \
              (set_color --bold $color_user) $USER $color_reset \
              (set_color --bold $color_host) $hostname $color_reset \
              (set_color --bold $color_cwd) (prompt_pwd) $color_reset \
              $color_reset
      end

      set fish_greeting
      fish_vi_key_bindings

      ${lib.getExe pkgs.zoxide} init fish | source
    '';
  };
}
