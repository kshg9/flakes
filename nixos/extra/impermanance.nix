{ inputs, ... }: {
  flake.nixosModules.extra_impermanence =
    {
      lib,
      config,
      ...
    }:
    let
      cfg = config.persistance;
    in
    {
      imports = [
        inputs.impermanence.nixosModules.impermanence
      ];

      config = lib.mkIf cfg.enable {
        fileSystems."/persist".neededForBoot = true;
        fileSystems."/home".neededForBoot = true;
        fileSystems."/var/log".neededForBoot = true;
        programs.fuse.userAllowOther = true;
        boot.tmp.cleanOnBoot = lib.mkDefault true;

        boot.initrd.systemd.enable = true;

        environment.persistence = {
          "/persist/userdata".users."${cfg.user}" = {
            directories = cfg.data.directories;
            files = cfg.data.files;
          };

          "/persist/usercache".users."${cfg.user}" = {
            directories = cfg.cache.directories;
            files = cfg.cache.files;
          };

          "/persist/system" = {
            hideMounts = true;
            directories = [
              "/etc/nixos"
              "/var/log"
              "/var/lib/bluetooth"
              "/var/lib/nixos"
              "/var/lib/systemd/coredump"
              "/etc/NetworkManager/system-connections"
              "/tmp"
            ]
            ++ cfg.directories;
            files = [
              "/etc/machine-id"
              "/etc/lact/config.yaml"
              {
                file = "/var/keys/secret_file";
                parentDirectory = {
                  mode = "u=rwx,g=,o=";
                };
              }
            ]
            ++ cfg.files;
          };
        };

        boot.initrd.systemd.services.rollback = lib.mkIf cfg.nukeRoot.enable {
          description = "Rollback BTRFS root subvolume to a pristine state";
          wantedBy = [ "initrd.target" ];

          after = [ "systemd-cryptsetup@${cfg.luksName}.service" ];
          before = [ "sysroot.mount" ];

          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";

          script = ''
            mkdir -p /mnt
            mount -o subvol=/ /dev/mapper/${cfg.luksName} /mnt

            btrfs subvolume list -o /mnt/root |
              cut -f9 -d' ' |
              while read subvolume; do
                echo "deleting /$subvolume subvolume..."
                btrfs subvolume delete "/mnt/$subvolume"
              done &&
              echo "deleting /root subvolume..." &&
              btrfs subvolume delete /mnt/root
            echo "restoring blank /root subvolume..."
            btrfs subvolume snapshot /mnt/root-blank /mnt/root

            umount /mnt
          '';
        };
      };
    };
}
