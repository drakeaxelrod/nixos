# draxel's Home Manager configuration
{ config, pkgs, inputs, ... }:

let
  # NixOS flake operations script - shared with devshell
  nx = pkgs.writeShellScriptBin "nx" (builtins.readFile ../../../scripts/nx.sh);
in
{
  imports = [
    ./core
    ./shell
    ./dev
    ./editors
    ./desktop
    ./apps
    # Zen Browser - modern Firefox-based browser with vertical tabs
    inputs.zen-browser.homeModules.default
  ];

  home.username = "draxel";
  home.homeDirectory = "/home/draxel";
  home.stateVersion = "25.11";

  # Zen Browser
  programs.zen-browser.enable = true;

  # User packages
  home.packages = with pkgs; [
    # Custom scripts
    nx

    # CLI tools (these are configured in shell/)
    # eza, bat, fzf, zoxide are configured via programs.*

    # Git tools (configured in dev/git.nix and dev/lazygit.nix)
    # git, lazygit, gh are configured via programs.*

    # Development (main dev tools are in dev/tools.nix)
    nix-direnv  # Nix-specific direnv integration

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

    # Web browsers
    # firefox
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
