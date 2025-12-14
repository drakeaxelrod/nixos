# Declarative disk layout: 2x NVMe, LUKS2, Btrfs RAID 1, 10 subvolumes
#
# This config:
# - Partitions both NVMe drives identically (1GB EFI + rest LUKS)
# - Creates LUKS2 containers on both drives (prompts for password twice - use SAME password!)
# - Creates Btrfs RAID 1 filesystem across both LUKS containers
# - Creates 10 subvolumes with appropriate mount options
#
# Run with: nix run github:nix-community/disko -- --mode disko ./disko-config.nix

{
  disko.devices = {
    disk = {
      # First NVMe drive - contains EFI and primary LUKS/Btrfs
      nvme0 = {
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
                };
                # Password prompt during disko run
                # For automated installs: passwordFile = "/tmp/disk-password";
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-L" "nixos"
                    "-d" "raid1"
                    "-m" "raid1"
                    "/dev/mapper/cryptroot1"  # Second LUKS device joins RAID
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

      # Second NVMe drive - EFI backup and LUKS for RAID 1 member
      nvme1 = {
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
                };
                # This LUKS device is added to the RAID via nvme0's extraArgs
                # No content here - it becomes part of the btrfs raid1
              };
            };
          };
        };
      };
    };
  };
}
