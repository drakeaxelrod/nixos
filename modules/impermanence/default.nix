# Impermanence - ephemeral root filesystem
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.impermanence;
  userCfg = config.modules.users;
in
{
  options.modules.impermanence = {
    enable = lib.mkEnableOption "Impermanence (ephemeral root)";

    persistPath = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "Path to persistent storage";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure persist subvolume is mounted early
    fileSystems.${cfg.persistPath}.neededForBoot = true;

    environment.persistence.${cfg.persistPath} = {
      hideMounts = true;

      # System directories to persist
      directories = [
        "/etc/nixos"
        "/etc/NetworkManager/system-connections"
        "/etc/ssh"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/tailscale"
        "/var/lib/libvirt"
        "/var/lib/docker"
        "/var/lib/sops-nix"
      ];

      # System files to persist
      files = [
        "/etc/machine-id"
        "/etc/adjtime"
      ];

      # User persistence
      users.${userCfg.primaryUser} = {
        directories = [
          "Downloads"
          "Documents"
          "Pictures"
          "Videos"
          "Projects"
          ".gnupg"
          ".ssh"
          ".local/share/keyrings"
          ".config/sops"
          ".mozilla"
          ".config/discord"
          ".steam"
          { directory = ".local/share/Steam"; method = "symlink"; }
        ];
        files = [
          ".zsh_history"
        ];
      };
    };

    # Boot script to wipe root on every boot
    # This requires a blank @rootfs-blank snapshot to exist
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      mkdir -p /mnt
      mount -o subvol=/ /dev/mapper/cryptroot1 /mnt

      # Delete old root, create fresh one from blank snapshot
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
