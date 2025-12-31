# User configuration for bamse
# Penetration testing user
{ config, pkgs, lib, vars, ... }:

{
  # ==========================================================================
  # NixOS User Account
  # ==========================================================================

  users.users.bamse = {
    isNormalUser = true;
    description = "bamse - pentest user";
    shell = pkgs.zsh;
    initialPassword = "changeme";  # Change on first login!
    extraGroups = [
      "wheel"
      "networkmanager"
      "libvirtd"
      "docker"
      "wireshark"  # Packet capture
      "dialout"    # Serial devices
      "plugdev"    # USB devices
    ];
  };

  # ==========================================================================
  # Home-Manager Configuration
  # ==========================================================================

  home-manager.users.bamse = import ./home;
}
