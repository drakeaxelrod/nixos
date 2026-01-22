# Keybase - Secure messaging, file sharing, and identity verification
#
# Keybase provides:
# - End-to-end encrypted chat
# - Encrypted file storage (Keybase Filesystem - KBFS)
# - Git repository hosting
# - Identity verification via social proofs
#
{ config, lib, pkgs, ... }:

{
  options.modules.services.keybase = {
    enable = lib.mkEnableOption "Keybase secure messaging and file sharing";

    enableKBFS = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Keybase Filesystem (KBFS) for encrypted file storage";
    };

    enableGUI = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Keybase GUI application";
    };

    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/keybase";
      description = "Mount point for KBFS";
    };
  };

  config = lib.mkIf config.modules.services.keybase.enable {
    # Enable Keybase service
    services.keybase.enable = true;

    # Enable KBFS if requested
    services.kbfs = lib.mkIf config.modules.services.keybase.enableKBFS {
      enable = true;
      mountPoint = config.modules.services.keybase.mountPoint;
    };

    # Install Keybase packages
    environment.systemPackages = with pkgs; [
      keybase        # CLI tools
      kbfs           # Keybase filesystem
    ] ++ lib.optionals config.modules.services.keybase.enableGUI [
      keybase-gui    # GUI application
    ];

    # Keybase requires a few system tweaks for proper operation
    # Allow Keybase to use FUSE for KBFS
    programs.fuse.userAllowOther = lib.mkIf config.modules.services.keybase.enableKBFS true;

    # Fix DNS resolution issues with systemd user services and Tailscale MagicDNS
    # Keybase service needs to wait for network to be fully configured
    systemd.user.services.keybase = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    systemd.user.services.kbfs = lib.mkIf config.modules.services.keybase.enableKBFS {
      after = [ "network-online.target" "keybase.service" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
