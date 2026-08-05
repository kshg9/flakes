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
      users.users.${user}.initialHashedPassword =
        "$6$XjYPyh/Kt30OoNKn$EeNci/RYnQQKgkGilJwPkh5oreAhiu16HpH2LAsAb54NrE85O5rOowZ5HQQyKUX7dTIsA5q3K7eOAtCfQtqc5/";

      # Apps under test on this user's hjem profile. Just add the wrapped/normal
      # package here and `nixos-rebuild build-vm --flake .#sandbox` to try it.
      hjem.users.${user}.packages = [
        pkgs.yazi
      ];
    };
}