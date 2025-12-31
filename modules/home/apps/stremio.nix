# =============================================================================
# Stremio - Media Streaming Application
# =============================================================================
#
# Stremio is a modern media center that gives you the freedom to watch
# everything you want instantly.
#
# Features:
# - Stream movies, TV shows, web channels, live TV
# - Access content from various sources via add-ons
# - Sync watch history across devices
# - Download content for offline viewing
#
# =============================================================================

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    stremio  # Modern media center
  ];
}
