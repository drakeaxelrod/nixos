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

    # Desktop environment (GNOME) - includes fonts, GTK, Qt
    modules.home.desktop.gnome
    # modules.home.desktop.plasma  # Or use Plasma instead

    # Shell configurations
    modules.home.shell.bat
    modules.home.shell.direnv
    modules.home.shell.fzf
    modules.home.shell.lsd
    modules.home.shell.starship
    modules.home.shell.zoxide
    modules.home.shell.zsh

    # Development tools
    modules.home.dev.git
    modules.home.dev.lazygit
    modules.home.dev.tools

    # Editors
    modules.home.editors.claudeCode
    modules.home.editors.neovim
    modules.home.editors.vscode

    # Applications
    modules.home.apps.moonlight
    modules.home.apps.steam
    modules.home.apps.stremio
    modules.home.apps.zenBrowser
  ];

  home.username = "draxel";
  home.homeDirectory = "/home/draxel";
  home.stateVersion = "25.11";

  # Link wallpapers from nixos config to Pictures directory
  # Example: Makes assets/wallpapers available at ~/Pictures/wallpapers
  home.file."Pictures/wallpapers" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/assets/wallpapers";
    recursive = true;
  };


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
        "application/pdf" = "org.gnome.Evince.desktop";
        "image/png" = "org.gnome.eog.desktop";
        "image/jpeg" = "org.gnome.eog.desktop";
        "inode/directory" = "org.gnome.Nautilus.desktop";
      };
    };

    configFile."mimeapps.list".force = true;
  };
}
