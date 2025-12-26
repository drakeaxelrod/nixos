# Btrfs snapshots with btrbk
{ config, pkgs, lib, ... }:

{
  # Btrfs filesystem scrub
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # Snapshot management with btrbk
  services.btrbk.instances = {
    local = {
      onCalendar = "hourly";
      settings = {
        timestamp_format = "long";
        snapshot_preserve_min = "2d";
        snapshot_preserve = "24h 7d 4w";

        volume."/" = {
          subvolume."/home" = {
            snapshot_dir = "/.snapshots/home";
          };
          subvolume."/work" = {
            snapshot_dir = "/.snapshots/work";
            snapshot_preserve = "48h 14d 8w";
          };
        };
      };
    };

    system = {
      onCalendar = "weekly";
      settings = {
        timestamp_format = "long";
        snapshot_preserve_min = "7d";
        snapshot_preserve = "4w";

        volume."/" = {
          subvolume."/@rootfs" = {
            snapshot_dir = "/.snapshots/rootfs";
          };
        };
      };
    };
  };
}
