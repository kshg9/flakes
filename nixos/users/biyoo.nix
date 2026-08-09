# biyoo — the ephemeral sandbox/dev account (base, plus apps currently under
# test). Add apps here to try them out in build-vm; the list merges with the
# base profile, no duplication.
{
  self,
  ...
}: {
  flake.nixosModules.userBiyoo =
    {
      pkgs,
      ...
    }:
    let
      user = "biyoo";
    in
    {
      imports = [ (self.userBase user) ];

      # Disposable VM → known dev password. Password: `vm`.
      users.users.${user} = {
        initialHashedPassword =
          "$6$LDUu.Y9KJo7bM5by$0MQdp3lNXE4qSUtuordK2EnS8PdY2e3XBZ3AgnQG9k8.Q7ySnwgNxZGq5UqNxXXxieyFXJZapvv34cKNNeNGg/";
        # sandbox is a dev box and biyoo its only user — no secrets here, just sudo.
        extraGroups = [ "wheel" ];
      };

      # Apps under test on this user's hjem profile. Just add the wrapped/normal
      # package here and `nixos-rebuild build-vm --flake .#sandbox` to try it.
      hjem.users.${user}.packages = [
        pkgs.yazi
      ];
    };
}