# kdj's per-user module — layered on the shared base, owns its own name.
{
  self,
  ...
}: {
  flake.nixosModules.userKdj =
    { pkgs, ... }:
    let
      user = "kdj";
    in
    {
      imports = [
        (self.userBase user)
        self.nixosModules.llm-agents
        self.nixosModules.firefox
      ];

      # Password lives in a file on the persisted subvol (/persist/passwords/kdj),
      # read by update-users-groups on every boot — impermanence wipes /etc/shadow,
      # so the account is recreated fresh and this hash is always applied. Change
      # it with the `changepass` command (updates the file + /etc/shadow now).
      # kdj is the full-access user (sudo + NetworkManager) — not the base's job
      # anymore; opts in right here.
      users.users.${user} = {
        hashedPasswordFile = "/persist/passwords/${user}";
        extraGroups = [ "wheel" "networkmanager" "keys" ];
      };

      # ===== hjem: kdj's home profile =========================================
      # niri is now plain nixpkgs niri (desktop.nix) — no wrapped NIRI_CONFIG
      # store path. Its whole config is a normal hjem-managed dotfile at
      # `~/.config/niri/config.kdl`, sourced from files/niri/config.kdl (the
      # byte-captured output of the old wrapper's toKdl renderer, pluie-style).
      # The focus-ring accent there is the catppuccin default (mauve #cba6f7);
      # bump it there if you switch flake.ctp.accent.
      hjem.users.${user} = {
        # helix: kdj-only editor. Stock nixpkgs `helix` reads ~/.config/helix;
        # config.toml selects the custom kanagawa-transparent theme (inherits the
        # bundled kanagawa, unsets the opaque bg scopes → transparent).
        xdg.config.files = {
          "helix/config.toml".source = ./files/helix/config.toml;
          "helix/themes/catppuccin_mocha-transparent.toml".source =
            ./files/helix/catppuccin_mocha-transparent.toml;
          "nvim/init.lua".source = ./files/nvim/init.lua;
          "sioyek/prefs_user.config".source = ./files/sioyek/prefs_user.config;
          "git/config".source = ./files/git/config;
          "jj/config.toml".source = ./files/jujutsu/config.toml;
        };
        # kdj-only extras on top of the shared base. Keep the base in base.nix;
        # only what is specific to kdj goes here. This is where dev tooling lives
        # (a restricted guest like yjh never sees these).
        packages = with pkgs; [
          # kdj's personal / desktop apps
          # chromium
          #obsidian
          #anki-bin
          #vesktop
          rclone
          # (use tldeer if in unstable or use tealdeer)
          #tealdeer

          # dev tools specific to this founder
          vscodium-fhs
          emacs-pgtk
          helix
          tmux
          zk
          neovim
          nixd
          statix
          nixfmt
          nix-diff
          hydra-check
          treefmt
          direnv
          jujutsu
          
          # CLI tools & utils
          pciutils
          psmisc
          socat
          sops
          lsof
          rustscan
          onefetch
          
          # Apps
          sioyek
        ];
      };
    };
}