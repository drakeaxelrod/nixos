# Disko configuration for nixos
# Simple Btrfs layout with subvolumes
#
# Usage: disko --mode disko ./disko.nix
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # Default to /dev/sda - update for your hardware
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            # Root partition - btrfs with subvolumes
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [ "compress=zstd" "noatime" "discard=async" ];
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
