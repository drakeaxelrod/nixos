# Declarative disk layout: 2x NVMe, LUKS2, Btrfs RAID 1, 10 subvolumes
#
# Based on: https://github.com/nix-community/disko/blob/master/example/luks-btrfs-raid.nix
#
# Key insight: Disko processes disks ALPHABETICALLY by name.
# - disk1 (nvme0): LUKS only, NO btrfs content - just opens the encrypted device
# - disk2 (nvme1): LUKS with btrfs RAID 1 content referencing /dev/mapper/cryptroot0
#
# For interactive install:
#   nix run github:nix-community/disko -- --mode disko ./disko.nix
#
# For automated install (create /tmp/secret.key first):
#   echo -n "your-passphrase" > /tmp/secret.key
#   nix run github:nix-community/disko -- --mode disko ./disko.nix

{
  disko.devices = {
    disk = {
      # IMPORTANT: "disk1" comes before "disk2" alphabetically!
      # This ensures cryptroot0 is opened BEFORE btrfs tries to create RAID

      # First NVMe - EFI + LUKS (no btrfs content here!)
      disk1 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
                mountOptions = [ "fmask=0022" "dmask=0022" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot0";
                settings = {
                  allowDiscards = true;
                  # Uncomment for automated installs:
                  # keyFile = "/tmp/secret.key";
                  crypttabExtraOpts = [ "tpm2-device=auto" ]; # Use TPM2 if available
                };
                # NO content here - btrfs is defined on disk2
              };
            };
          };
        };
      };

      # Second NVMe - EFI backup + LUKS + Btrfs RAID 1
      disk2 = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                # Second EFI for redundancy - not mounted by default
                # Sync manually: rsync -av /boot/efi/ /mnt/efi-backup/
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot1";
                settings = {
                  allowDiscards = true;
                  # Uncomment for automated installs:
                  # keyFile = "/tmp/secret.key";
                  crypttabExtraOpts = [ "tpm2-device=auto" ]; # Use TPM2 if available
                };
                # Btrfs RAID 1 content goes HERE (on the second disk alphabetically)
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-L" "nixos"
                    "-d" "raid1"
                    "-m" "raid1"
                    "/dev/mapper/cryptroot0"  # First LUKS device (already open)
                  ];
                  subvolumes = {
                    "@rootfs" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@work" = {
                      mountpoint = "/work";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@libvirt" = {
                      mountpoint = "/var/lib/libvirt";
                      mountOptions = [ "nodatacow" "noatime" ];
                    };
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "nodatacow" "noatime" ];
                    };
                    "@cache" = {
                      mountpoint = "/var/cache";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@tmp" = {
                      mountpoint = "/var/tmp";
                      mountOptions = [ "nodatacow" "noatime" ];
                    };
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [ "compress=zstd" "noatime" ];
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
