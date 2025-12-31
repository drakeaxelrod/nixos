# System-wide essential packages
# These are available before home-manager activates
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # Essential CLI tools needed by system scripts
    jq      # JSON processor (required by nx script)
    git     # Version control
    curl    # HTTP client
    wget    # File downloader

    # Text editor
    neovim  # Modern vim

    # File operations
    lsd     # Modern ls
    ripgrep # Fast grep
    fd      # Fast find
    bat     # Cat with syntax highlighting

    # System utilities
    htop    # Process monitor
    tree    # Directory listing
    file    # File type detection

    # Network utilities
    dig     # DNS lookup
    nmap    # Network scanner
  ];
}
