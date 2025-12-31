# fastfetch - Fast system information tool
{ config, pkgs, lib, ... }:

{
  programs.fastfetch = {
    enable = true;

    settings = {
      logo = {
        source = "nixos";
        padding = {
          top = 1;
          left = 2;
        };
      };

      display = {
        separator = " → ";
        color = "blue";
      };

      modules = [
        "title"
        "separator"
        "os"
        "host"
        "kernel"
        "uptime"
        "packages"
        "shell"
        "display"
        "de"
        "wm"
        "wmtheme"
        "theme"
        "icons"
        "font"
        "cursor"
        "terminal"
        "terminalfont"
        "cpu"
        "gpu"
        "memory"
        "disk"
        "localip"
        "battery"
        "locale"
        "break"
        "colors"
      ];
    };
  };

  # Alias
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    ff = "fastfetch";
    neofetch = "fastfetch";  # Replace neofetch
  };
}
