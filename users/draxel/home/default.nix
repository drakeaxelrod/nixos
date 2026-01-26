# draxel's Home Manager configuration
{ config, pkgs, inputs, modules, ... }:

let
  # NixOS flake operations script - shared with devshell
  nx = pkgs.writeShellScriptBin "nx" (builtins.readFile ../../../scripts/nx.sh);
in
{
  imports = [
    # Zen Browser - modern Firefox-based browser with vertical tabs
    # Plasma Manager - KDE Plasma configuration

    # Desktop environment (Plasma) - includes fonts, GTK, Qt
    modules.home.desktop.plasma

    # Shell configurations
    modules.home.shell.bat
    modules.home.shell.direnv
    modules.home.shell.fzf
    modules.home.shell.grc
    modules.home.shell.lsd
    modules.home.shell.starship
    modules.home.shell.zoxide
    modules.home.shell.zsh
    modules.home.shell.fd
    modules.home.shell.ripgrep
    modules.home.shell.jq
    modules.home.shell.fastfetch

    # Development tools
    modules.home.dev.git
    modules.home.shell.delta  # Git diff highlighter
    # modules.home.dev.lazygit
    # Language-specific
    modules.home.dev.rust
    modules.home.dev.go
    # modules.home.dev.nodejs
    # modules.home.dev.python
    # modules.home.dev.java
    modules.home.dev.c
    modules.home.dev.lua
    modules.home.dev.nix
    # Utilities
    # modules.home.dev.database
    # modules.home.dev.api
    # modules.home.dev.build

    # Editors
    modules.home.editors.claudeCode
    modules.home.editors.nixvim
    modules.home.editors.vscode

    # Applications
    modules.home.apps.moonlight
    modules.home.apps.steam
    # modules.home.apps.stremio  # Disabled: requires orphaned qtwebengine-5.15.19 (see nixpkgs#437992)
                                  # Use web version instead: https://web.stremio.com
    modules.home.apps.zenBrowser
  ];

  home.username = "draxel";
  home.homeDirectory = "/home/draxel";
  home.stateVersion = "25.11";

  # OpenCommit configuration (AI-powered git commits via gacp)
  home.sessionVariables = {
    OCO_AI_PROVIDER = "ollama";
    OCO_API_URL = "http://127.0.0.1:11434/api/chat";
    OCO_MODEL = "llama3.2";
    OCO_LANGUAGE = "en";
    OCO_EMOJI = "false";
    OCO_DESCRIPTION = "true";
  };

  # Link wallpapers from nixos config to Pictures directory
  # Example: Makes assets/wallpapers available at ~/Pictures/wallpapers
  home.file."Pictures/wallpapers" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/assets/wallpapers";
    recursive = true;
  };

  # Profile image for display managers (SDDM, GDM, KDM, LightDM)
  # ~/.face is the standard location for user avatars
  home.file.".face".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/assets/profile/me.jpg";


  # User packages
  home.packages = with pkgs; [
    # Custom scripts
    nx

    # Development
    nix-direnv  # Nix-specific direnv integration

    # Communication
    discord

    # Audio
    pavucontrol  # Audio control

    # Hardware
    vial  # Keyboard configuration (QMK/Vial firmware)

    # Virtualization
    virt-manager        # VM management GUI
    virt-viewer         # VM viewer
    # Note: looking-glass-client and scream are installed via VFIO modules

    # My own custom flake for keyboard learning
    inputs.yxa.packages.${pkgs.stdenv.hostPlatform.system}.visual-guide
  ];

  # Use XDG config directory for zsh (new default in 26.05)
  programs.zsh.dotDir = "${config.xdg.configHome}/zsh";

  # XDG directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      music = "${config.home.homeDirectory}/Music";
      desktop = "${config.home.homeDirectory}/Desktop";
      templates = "${config.home.homeDirectory}/Templates";
      publicShare = "${config.home.homeDirectory}/Public";
      extraConfig = {
        XDG_PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
        XDG_WORK_DIR = "/work";
      };
    };

    # MIME type associations
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "zen.desktop";
        "x-scheme-handler/http" = "zen.desktop";
        "x-scheme-handler/https" = "zen.desktop";
        "application/pdf" = "org.kde.okular.desktop";
        "image/png" = "org.kde.gwenview.desktop";
        "image/jpeg" = "org.kde.gwenview.desktop";
        "inode/directory" = "org.kde.dolphin.desktop";
      };
    };

    configFile."mimeapps.list".force = true;
  };
}
