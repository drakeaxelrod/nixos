# User-level packages
{ config, pkgs, ... }:

let
  # NixOS flake operations script - shared with devshell
  nx = pkgs.writeShellScriptBin "nx" (builtins.readFile ../../../scripts/nx.sh);
in
{
  programs.zen-browser.enable = true;

  home.packages = with pkgs; [
    # Custom scripts
    nx
    # CLI tools
    eza          # Modern ls
    bat          # Modern cat
    fzf          # Fuzzy finder
    zoxide       # Smart cd
    lazygit      # Git TUI
    jq           # JSON processor
    yq           # YAML processor

    # Development
    direnv
    nix-direnv
    nixfmt

    # Security/Pentest (uncomment as needed)
    # nmap
    # burpsuite  # Unfree
    # ghidra

    # Media (uncomment as needed)
    # vlc
    # spotify

    # Communication (uncomment as needed)
    discord
    # slack

    # Audio
    pavucontrol  # Audio control

    # web browser
    firefox

  ];
}
