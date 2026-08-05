{ ... }: {
  flake.wrappers.starship = { wlib, ... }: {
    imports = [ wlib.wrapperModules.starship ];

    preset = [ "plain-text-symbols" ];
    settings = {
      format = "$directory $git_branch$git_status cmd_duration $python\n$character";

      directory = {
        truncation_length = 2;
        truncation_symbol = "…/";
      };

      cmd_duration = {
        min_time = 0;
        format = "[$duration ](bold dimmed)";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };
}
