# libvirt/QEMU/KVM virtualization
#
# Usage:
#   modules.virtualization.libvirt = {
#     enable = true;
#     users = [ "draxel" ];  # Users who can manage VMs
#   };
#
# Networking:
#   By default, libvirt provides NAT networking via virbr0 which works
#   out of the box. VMs can access the internet but are isolated from
#   the host network.
#
#   For bridged networking (VMs on same network as host), you have options:
#   1. Use macvtap in VM config (direct NIC attachment, no bridge needed)
#   2. Create a NetworkManager bridge manually (no rebuild needed)
#   3. Use modules.networking.bridge for declarative bridge
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.virtualization.libvirt;
in
{
  options.modules.virtualization.libvirt = {
    enable = lib.mkEnableOption "libvirt virtualization";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "draxel" ];
      description = "Users who can manage VMs (added to libvirtd group)";
    };

    tpm = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable TPM emulation (required for Windows 11)";
    };

    spiceUSB = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable SPICE USB redirection";
    };

    defaultNetwork = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable libvirt's default NAT network (virbr0)";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = cfg.tpm;
        # OVMF images are now available by default (removed in NixOS 24.11+)
      };
    };

    programs.virt-manager.enable = true;
    virtualisation.spiceUSBRedirection.enable = cfg.spiceUSB;

    # Add users to libvirtd group
    users.groups.libvirtd.members = cfg.users;

    # Networking tools and VM utilities
    environment.systemPackages = with pkgs; [
      bridge-utils  # brctl for bridge management
      iproute2      # ip link for interface management
      virtiofsd     # Virtio filesystem daemon (shared folders)
    ];

    # Ensure vhost modules are loaded for network performance
    boot.kernelModules = [ "vhost" "vhost_net" ];

    # Enable default NAT network (virbr0) - autostarted by libvirt
    # This provides out-of-the-box VM networking without configuration
    networking.firewall.trustedInterfaces = lib.mkIf cfg.defaultNetwork [ "virbr0" ];
  };
}
