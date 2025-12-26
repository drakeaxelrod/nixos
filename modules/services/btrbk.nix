# Btrfs snapshots with btrbk
{ config, lib, pkgs, ... }:

{
  options.modules.services.btrbk = {
    enable = lib.mkEnableOption "btrbk Btrfs snapshots";

    homeSnapshots = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable hourly snapshots of /home";
    };

    workSnapshots = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable hourly snapshots of /work";
    };

    rootfsSnapshots = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable weekly snapshots of @rootfs";
    };
  };

  config = lib.mkIf config.modules.services.btrbk.enable {
    services.btrbk = {
      instances = lib.mkMerge [
        # Hourly snapshots for home and work
        (lib.mkIf (config.modules.services.btrbk.homeSnapshots || config.modules.services.btrbk.workSnapshots) {
          local = {
            onCalendar = "hourly";
            settings = {
              timestamp_format = "long";
              snapshot_preserve_min = "2d";
              snapshot_preserve = "24h 7d 4w";

              volume."/" = lib.mkMerge [
                (lib.mkIf config.modules.services.btrbk.homeSnapshots {
                  subvolume."/home" = {
                    snapshot_dir = "/.snapshots/home";
                  };
                })
                (lib.mkIf config.modules.services.btrbk.workSnapshots {
                  subvolume."/work" = {
                    snapshot_dir = "/.snapshots/work";
                    snapshot_preserve = "48h 14d 8w";
                  };
                })
              ];
            };
          };
        })

        # Weekly rootfs snapshots
        (lib.mkIf config.modules.services.btrbk.rootfsSnapshots {
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
        })
      ];
    };
  };
}
