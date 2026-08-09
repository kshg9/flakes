# yjh — restricted guest account. NO sudo/wheel, minimal packages, no dev
# tooling, and no `nix`. Home is wiped on reboot under impermanence AND wiped
# weekly while running by `modules/guest-wipe.nix`.
{
  self,
  ...
}: {
  flake.nixosModules.userYjh =
    {
      lib,
      pkgs,
      ...
    }:
    let
      user = "yjh";
    in
    {
      imports = [ (self.userBase user) ];

      # Strip the base's wheel+networkmanager membership — no sudo, no NM
      # control. Root has no password, so `su` is a dead end too. Re-applied
      # every boot via update-users-groups (impermanence wipes /etc/shadow);
      # seed it with `changepass yjh`.
      #
      # NOTE: guest keeps the base's fish `environment` shell — uniform login
      # UX. (System bins are reachable by absolute path regardless, and the
      # weekly wipe keeps /home clean, so a stripped shell buys little.)
      users.users.${user} = {
        # `keys` lets yjh `read` files under /run/secrets (the dir itself is
        # root:keys 750). No wheel (no sudo; root has no password, so su is a
        # dead end too). Private keys stay 0600 root/kdj so yjh still can't
        # read those — only the pubkey is group readable.
        extraGroups = [ "keys" ];
        hashedPasswordFile = "/persist/passwords/${user}";
      };

      # Guest is limited to the common base (playerctl/brightnessctl/bibata)
      # plus a browser. No `nix`, no editors, no dev tooling — those are
      # kdj-profile-only (see kdj.nix).
      hjem.users.${user}.packages = with pkgs; [
        firefox
      ];

      guestWipe.users = [ user ];
    };
}