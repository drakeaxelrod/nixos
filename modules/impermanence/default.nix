# Impermanence - ephemeral root filesystem with smart defaults
#
# Automatically persists SYSTEM data for enabled services in /persist.
# User data in /home and /work are separate persistent Btrfs subvolumes.
#
# Usage:
#   modules.impermanence = {
#     enable = true;
#   };
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.impermanence;

  # Auto-detect what needs persisting based on enabled services
  # NOTE: /home, /work, /var/lib/libvirt, /var/log are persistent Btrfs subvolumes
  # Only system dirs that live in ephemeral /rootfs need persistence to /persist
  autoSystemDirs = lib.flatten [
    # Always needed - core system state
    "/var/lib/nixos"
    "/var/lib/systemd"           # systemd state (timers, random-seed, backlight, rfkill, etc.)
    "/var/lib/AccountsService"   # user account metadata (avatars, language, autologin)

    # Network
    (lib.optional config.networking.networkmanager.enable "/etc/NetworkManager/system-connections")
    (lib.optional config.services.tailscale.enable "/var/lib/tailscale")

    # Display Manager / Desktop (GNOME enables many of these implicitly)
    (lib.optional (config.services.displayManager.gdm.enable or false) "/var/lib/gdm")
    (lib.optional (config.services.desktopManager.gnome.enable or false) "/var/lib/colord")
    (lib.optional (config.services.desktopManager.gnome.enable or false) "/var/lib/geoclue")
    (lib.optional (config.services.upower.enable or false) "/var/lib/upower")
    (lib.optional (config.services.fprintd.enable or false) "/var/lib/fprint")
    (lib.optional (config.services.gnome.gnome-keyring.enable or false) "/var/lib/gnome")

    # Virtualization - handled by separate @libvirt subvolume in disko
    # (lib.optional config.virtualisation.libvirtd.enable "/var/lib/libvirt")
    (lib.optional config.virtualisation.docker.enable "/var/lib/docker")

    # Services
    (lib.optional config.services.openssh.enable "/etc/ssh")
    (lib.optional config.hardware.bluetooth.enable "/var/lib/bluetooth")

    # Security
    (lib.optional (config.sops.secrets or {} != {}) "/var/lib/sops-nix")
  ];

  autoSystemFiles = [
    "/etc/machine-id"  # Required by systemd, dbus, journald, and most services
    "/etc/adjtime"     # Hardware clock adjustment
  ];
in
{
  options.modules.impermanence = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable impermanence (ephemeral root filesystem)";
    };

    persistPath = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "Path to persistent storage";
    };

    # Extension points for additional system persistence
    extraDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional system directories to persist";
    };

    extraFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional system files to persist";
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems.${cfg.persistPath}.neededForBoot = true;

    environment.persistence.${cfg.persistPath} = {
      hideMounts = true;

      # System-level persistence only (/home is a separate persistent subvolume)
      directories = lib.unique (autoSystemDirs ++ cfg.extraDirectories);
      files = lib.unique (autoSystemFiles ++ cfg.extraFiles);
    };

    # Wipe root on boot (requires @rootfs-blank snapshot)
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      mkdir -p /mnt
      mount -o subvol=/ /dev/mapper/cryptroot1 /mnt

      # Safety check: Ensure critical subvolumes exist before wiping
      # This prevents data loss if disko setup failed
      CRITICAL_DIRS="/mnt/@persist /mnt/@home /mnt/@work /mnt/@nix"
      MISSING_DIRS=""
      for dir in $CRITICAL_DIRS; do
        if [ ! -d "$dir" ]; then
          MISSING_DIRS="$MISSING_DIRS $dir"
        fi
      done

      if [ -n "$MISSING_DIRS" ]; then
        echo "WARNING: Critical Btrfs subvolumes missing:$MISSING_DIRS"
        echo "Skipping rootfs wipe to prevent data loss!"
        echo "Please ensure all subvolumes are created before rebooting."
        umount /mnt
        exit 0
      fi

      if [ -d /mnt/@rootfs ]; then
        btrfs subvolume list -o /mnt/@rootfs 2>/dev/null | cut -d' ' -f9 | while read subvol; do
          btrfs subvolume delete "/mnt/$subvol" 2>/dev/null || true
        done
        btrfs subvolume delete /mnt/@rootfs 2>/dev/null || true
      fi

      if [ -d /mnt/@rootfs-blank ]; then
        btrfs subvolume snapshot /mnt/@rootfs-blank /mnt/@rootfs
      fi

      umount /mnt
    '';
  };
}
