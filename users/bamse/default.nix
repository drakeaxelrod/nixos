# User configuration for bamse
# Penetration testing user
{ config, pkgs, lib, ... }:

{
  # ==========================================================================
  # NixOS User Account
  # ==========================================================================

  users.users.bamse = {
    isNormalUser = true;
    description = "Bamse - Penetration Testing";
    shell = pkgs.zsh;
    initialPassword = "changeme";  # Change on first login!
    extraGroups = [
      "wheel"            # sudo access
      "networkmanager"   # network management
      "libvirtd"         # virtual machines
      "docker"           # containers
      "wireshark"        # packet capture
      "dialout"          # serial devices
      "plugdev"          # USB devices
    ];
  };

  # ==========================================================================
  # Home-Manager Configuration
  # ==========================================================================

  home-manager.users.bamse = import ./home;
}
