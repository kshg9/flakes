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
      # Wheel (sudo) is opt-in since the base's default got removed — sandbox is
      # a dev box and biyoo is its only user, so restore full access here.
      users.users.${user} = {
        initialHashedPassword =
          "$6$XjYPyh/Kt30OoNKn$EeNci/RYnQQKgkGilJwPkh5oreAhiu16HpH2LAsAb54NrE85O5rOowZ5HQQyKUUIX7dTIsA5q3K7eOAtCfQtqc5/";
        extraGroups = [ "wheel" ];
      };

      # Apps under test on this user's hjem profile. Just add the wrapped/normal
      # package here and `nixos-rebuild build-vm --flake .#sandbox` to try it.
      hjem.users.${user}.packages = [
        pkgs.yazi
      ];
    };
}