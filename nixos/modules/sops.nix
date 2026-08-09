{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.sops =
    { pkgs, config, ... }:
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      # Per-host boot key at the sops-nix recommended location. generateKey
      # creates it on first boot (only after at least one sops.secrets.* is
      # declared — see KB/sops.md). What survives is a per-host concern:
      # uriel persists it via impermanence; a fresh VM/cloud host swaps in a
      # known key (see the swap-and-reboot method in KB/sops.md).
      sops.age = {
        keyFile = "/var/lib/sops-nix/key.txt";
        generateKey = false;
      };

      # No sops.secrets.* here — which secrets a host decrypts is gated per
      # host (declared in each host's configuration.nix). Only the key plumbing
      # + editing tooling live in this shared module.
      #
      # Editing tooling: classic `sops` CLI + age (age-keygen for key mgmt).
      environment.systemPackages = with pkgs; [ sops age ];
    };
}