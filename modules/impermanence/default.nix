# Impermanence - ephemeral root filesystem with smart defaults
#
# Automatically persists data for enabled services.
# Just enable and specify users - it figures out the rest.
#
# Usage:
#   modules.impermanence = {
#     enable = true;
#     users = [ "draxel" ];
#   };
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.impermanence;

  # Auto-detect what needs persisting based on enabled services
  autoSystemDirs = lib.flatten [
    # Always needed
    [ "/var/lib/nixos" ]

    # Network
    (lib.optional config.networking.networkmanager.enable "/etc/NetworkManager/system-connections")
    (lib.optional config.services.tailscale.enable "/var/lib/tailscale")

    # Virtualization
    (lib.optional config.virtualisation.libvirtd.enable "/var/lib/libvirt")
    (lib.optional config.virtualisation.docker.enable "/var/lib/docker")

    # Services
    (lib.optional config.services.openssh.enable "/etc/ssh")
    (lib.optional config.hardware.bluetooth.enable "/var/lib/bluetooth")

    # Security
    (lib.optional (config.sops.secrets or {} != {}) "/var/lib/sops-nix")

    # System
    [ "/var/lib/systemd/coredump" ]
  ];

  autoSystemFiles = [
    "/etc/machine-id"
    "/etc/adjtime"
  ];

  # Default user directories - common dotfiles and data
  defaultUserDirs = [
    "Downloads" "Documents" "Pictures" "Videos" "Projects"
    ".gnupg" ".ssh" ".local/share/keyrings"
    ".config/nixos"
  ];

  # Auto-detect user directories based on enabled features
  autoUserDirs = lib.flatten [
    defaultUserDirs

    # Browser
    (lib.optional config.programs.firefox.enable ".mozilla")

    # Gaming
    (lib.optionals (config.programs.steam.enable or false) [
      ".steam"
      { directory = ".local/share/Steam"; method = "symlink"; }
    ])

    # Apps (check if packages are in system or user packages)
    (lib.optional (builtins.elem pkgs.discord (config.environment.systemPackages or [])) ".config/discord")
  ];

  defaultUserFiles = [ ".zsh_history" ".bash_history" ];
in
{
  options.modules.impermanence = {
    enable = lib.mkEnableOption "Impermanence (ephemeral root)";

    persistPath = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "Path to persistent storage";
    };

    # Users to persist (simple list - uses smart defaults)
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "draxel" ];
      description = "Users to set up persistence for (uses smart defaults)";
    };

    # Extension points for additional persistence
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

    extraUserDirectories = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
      default = [];
      description = "Additional directories to persist for all users";
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems.${cfg.persistPath}.neededForBoot = true;

    environment.persistence.${cfg.persistPath} = {
      hideMounts = true;

      # Smart system persistence
      directories = lib.unique (autoSystemDirs ++ cfg.extraDirectories);
      files = lib.unique (autoSystemFiles ++ cfg.extraFiles);

      # Smart user persistence
      users = lib.genAttrs cfg.users (_: {
        directories = lib.unique (autoUserDirs ++ cfg.extraUserDirectories);
        files = defaultUserFiles;
      });
    };

    # Wipe root on boot (requires @rootfs-blank snapshot)
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      mkdir -p /mnt
      mount -o subvol=/ /dev/mapper/cryptroot1 /mnt

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
