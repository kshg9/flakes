{ pkgs, ... }: {
  # Clean home directory by forcing applications to use XDG Base Directories
  flake.nixosModules.xdg = {
    environment.sessionVariables = {
      # XDG Base Directories
      XDG_CACHE_HOME  = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME   = "$HOME/.local/share";
      XDG_STATE_HOME  = "$HOME/.local/state";

      # Tool-specific XDG overrides
      ANDROID_USER_HOME = "$XDG_DATA_HOME/android";
      AWS_CONFIG_FILE = "$XDG_CONFIG_HOME/aws/config";
      AWS_SHARED_CREDENTIALS_FILE = "$XDG_CONFIG_HOME/aws/credentials";
      CARGO_HOME = "$XDG_DATA_HOME/cargo";
      GOPATH = "$XDG_DATA_HOME/go";
      GRADLE_USER_HOME = "$XDG_DATA_HOME/gradle";
      HISTFILE = "$XDG_STATE_HOME/bash/history"; # For bash (if ever used)
      LESSHISTFILE = "$XDG_STATE_HOME/less/history";
      NODE_REPL_HISTORY = "$XDG_STATE_HOME/node/history";
      PYTHON_HISTORY = "$XDG_STATE_HOME/python/history";
      SQLITE_HISTORY = "$XDG_STATE_HOME/sqlite/history";
    };
  };
}
