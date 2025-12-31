# =============================================================================
# Steam - Gaming Platform
# =============================================================================
#
# Steam is a digital distribution platform for PC gaming.
#
# Note: Steam itself is installed at the system level (see system configuration)
# This file configures home-manager specific Steam settings.
#
# Features configured:
# - Steam integration via home-manager
# - Desktop shortcuts and integration
#
# System-level Steam configuration should be in your NixOS configuration:
#   programs.steam = {
#     enable = true;
#     remotePlay.openFirewall = true;
#     dedicatedServer.openFirewall = true;
#   };
#
# =============================================================================

{ config, pkgs, ... }:

{
  # Note: The main Steam installation is typically done at the system level
  # If you want to manage Steam entirely through home-manager, uncomment:
  # home.packages = with pkgs; [
  #   steam
  #   steam-run  # Run non-NixOS binaries in Steam's FHS environment
  # ];

  # XDG desktop entries for Steam games will be automatically created
  # when Steam is installed at the system level
}
