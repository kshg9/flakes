{
  flake.diskoConfigurations.hostMain = {
    disko.devices = {
      disk.main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZALQ512HBLU-00BL2_S65DNX1T647774";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            swap = {
              size = "18G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "enc";
                settings = {
                  # TRIM/discard for SSD longevity
                  allowDiscards = true;
                };
                # disko will prompt for a passphrase during `disko --mode create`
                # to enroll a fido2 key or tpm later:
                #   systemd-cryptenroll --fido2-device=auto /dev/nvme0n1p3
                # if using TPM:
                #   systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1p3

                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/root-blank" = {
                      # never mounted — the factory-fresh template
                      # that the initrd rollback service snapshots from.
                      # After first install, make readonly:
                      #   mount /dev/mapper/enc /mnt -o subvol=/
                      #   btrfs property set /mnt/root-blank ro true
                      #   umount /mnt
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "noatime" ];
                    };
                    "/var-log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "noatime" ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
