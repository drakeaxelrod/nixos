# draxel's Home Manager configuration
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./core
    ./shell
    ./git.nix
    ./neovim.nix
    ./desktop
    ./packages.nix
    ./vscode.nix
    ./claude-code.nix
    # Zen Browser - modern Firefox-based browser with vertical tabs
    inputs.zen-browser.homeModules.default
  ];

  home.username = "draxel";
  home.homeDirectory = "/home/draxel";
  home.stateVersion = "25.11";

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
