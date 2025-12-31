# Home Manager configuration for bamse
# Penetration testing user
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Core modules (always imported)
    ../../../modules/home/core

    # Program modules
    ../../../modules/home/programs/shell
    ../../../modules/home/programs/editors
    ../../../modules/home/programs/desktop

    # User-specific configs
    ./git.nix
    ./pentest.nix
  ];

  home.username = "bamse";
  home.homeDirectory = "/home/bamse";
  home.stateVersion = "25.11";

  # ==========================================================================
  # Pentest-specific Packages
  # ==========================================================================

  home.packages = with pkgs; [
    # Browser
    brave

    # Note-taking
    obsidian
  ];

  # ==========================================================================
  # Pentest Environment Variables
  # ==========================================================================

  home.sessionVariables = {
    BROWSER = "brave";
    TERMINAL = "gnome-terminal";

    # Wayland
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";

    # Pentest paths
    WORDLISTS = "/run/current-system/sw/share/wordlists";
    SECLISTS = "/run/current-system/sw/share/seclists";
  };

  # ==========================================================================
  # Shell Aliases for Pentesting
  # ==========================================================================

  programs.zsh.shellAliases = {
    # Quick scans
    quickscan = "nmap -sV -sC -O";
    fullscan = "nmap -sV -sC -O -p-";
    stealthscan = "nmap -sS -sV -O -T2";
    udpscan = "nmap -sU --top-ports 100";

    # Web enumeration
    dirb = "feroxbuster -u";

    # Listeners
    listener = "nc -lvnp";
    webserver = "python3 -m http.server";

    # Proxy
    burpon = "export HTTP_PROXY=http://127.0.0.1:8080 HTTPS_PROXY=http://127.0.0.1:8080";
    burpoff = "unset HTTP_PROXY HTTPS_PROXY";
  };
}
