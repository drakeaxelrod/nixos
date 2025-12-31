# =============================================================================
# Moonlight - Game Streaming Client
# =============================================================================
#
# Moonlight is an open-source client for NVIDIA GameStream and Sunshine.
# Use this to stream games from a Windows PC running Sunshine.
#
# First-time setup:
# 1. On Windows: Install and configure Sunshine (https://github.com/LizardByte/Sunshine)
# 2. On NixOS: Run `moonlight-qt`
# 3. Add your Windows PC by IP or let it auto-discover on local network
# 4. Pair using the PIN shown on Windows
#
# =============================================================================

{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    moonlight-qt  # Qt-based Moonlight client for game streaming
  ];
}
