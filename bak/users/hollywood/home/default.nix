# Home Manager configuration for hollywood
# Developer user with Moonlight
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Core modules (always imported)
    ../../../modules/home/core

    # Program modules
    ../../../modules/home/programs/shell
    ../../../modules/home/programs/editors
    ../../../modules/home/programs/desktop
    ../../../modules/home/programs/desktop/moonlight.nix

    # User-specific configs
    ./git.nix
  ];

  home.username = "hollywood";
  home.homeDirectory = "/home/hollywood";
  home.stateVersion = "25.11";

  # ==========================================================================
  # Developer Packages
  # ==========================================================================

  home.packages = with pkgs; [
    # Browser
    brave

    # CLI tools
    btop
    ncdu
    tldr
    httpie
    jq

    # Development
    docker-compose
  ];

  # ==========================================================================
  # Session Variables
  # ==========================================================================

  home.sessionVariables = {
    BROWSER = "brave";
    TERMINAL = "gnome-terminal";

    # Wayland
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };
}
