# User-level packages
{ config, pkgs, ... }:

{
  #programs.zen-browser.enable = true;
  home.packages = with pkgs; [
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

    # Security/Pentest (uncomment as needed)
    # nmap
    # burpsuite  # Unfree
    # ghidra

    # Media (uncomment as needed)
    # vlc
    # spotify

    # Communication (uncomment as needed)
    # discord
    # slack

    # web browser
    firefox
    
  ];
}
