# Home Manager configuration for bamse
# Penetration testing user
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./pentest.nix
  ];

  home.username = "bamse";
  home.homeDirectory = "/home/bamse";
  home.stateVersion = "25.11";

  # ==========================================================================
  # Shell Configuration
  # ==========================================================================

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
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

      # Common commands
      ll = "ls -lh";
      la = "ls -lah";
      ".." = "cd ..";
      "..." = "cd ../..";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$character";
    };
  };

  # ==========================================================================
  # Git Configuration
  # ==========================================================================

  programs.git = {
    enable = true;
    userName = "Bamse";
    userEmail = "bamse@honeypot.local";
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  # ==========================================================================
  # Environment
  # ==========================================================================

  home.packages = with pkgs; [
    # Browser
    brave

    # Note-taking
    obsidian

    # Basic tools
    tree
    ripgrep
    fd
    bat
    eza
  ];

  home.sessionVariables = {
    BROWSER = "brave";
    EDITOR = "nvim";
    TERMINAL = "gnome-terminal";

    # Wayland
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";

    # Pentest paths
    WORDLISTS = "/run/current-system/sw/share/wordlists";
    SECLISTS = "/run/current-system/sw/share/seclists";

    # Metasploit database
    MSF_DATABASE_CONFIG = "${config.home.homeDirectory}/.msf4/database.yml";
  };

  # ==========================================================================
  # XDG directories
  # ==========================================================================

  xdg.enable = true;
}
