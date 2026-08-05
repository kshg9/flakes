{
  self,
  ...
}: {
  flake.overlays.default =
    final: prev:
    let
      system = prev.stdenv.hostPlatform.system;
      myPkgs = self.packages.${system} or { };
      # Add only packages that don't already exist in nixpkgs. Shadowing
      # existing ones (fish/starship/qalc) would change the drv of anything
      # that depends on them — kitty's nativeBuildInputs pulls in fish, so a
      # shadowed fish makes kitty uncached → source build → flaky
      # test_fish_integration (nixpkgs#4759).
      # NOTE: must be `prev // addPkgs`, NOT `optionalAttrs (...) addPkgs` —
      # the optionalAttrs form silently drops the whole merge (returns the
      # set, which the overlay machinery then ignores). `prev //` is the only
      # form that actually applies.
      addPkgs = builtins.removeAttrs myPkgs (builtins.attrNames prev);
    in
    prev // addPkgs;
}
