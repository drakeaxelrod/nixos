# GNOME Terminal with One Dark Pro theme
{ config, pkgs, lib, ... }:

{
  dconf.settings = {
    "org/gnome/terminal/legacy" = {
      theme-variant = "dark";
      default-show-menubar = false;
    };

    "org/gnome/terminal/legacy/profiles:" = {
      default = "b1dcc9dd-5262-4d8d-a863-c897e6d979b9";
      list = [ "b1dcc9dd-5262-4d8d-a863-c897e6d979b9" ];
    };

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      visible-name = "One Dark Pro";
      use-system-font = false;
      font = "Lilex Nerd Font 10";
      use-theme-colors = false;
      # One Dark Pro colors
      foreground-color = "#abb2bf";
      background-color = "#282c34";
      bold-color = "#abb2bf";
      bold-color-same-as-fg = true;
      # Palette: Black, Red, Green, Yellow, Blue, Purple, Cyan, White (normal + bright)
      palette = [
        "#282c34"  # black
        "#e06c75"  # red
        "#98c379"  # green
        "#e5c07b"  # yellow
        "#61afef"  # blue
        "#c678dd"  # purple
        "#56b6c2"  # cyan
        "#abb2bf"  # white
        "#5c6370"  # bright black
        "#e06c75"  # bright red
        "#98c379"  # bright green
        "#e5c07b"  # bright yellow
        "#61afef"  # bright blue
        "#c678dd"  # bright purple
        "#56b6c2"  # bright cyan
        "#ffffff"  # bright white
      ];
      cursor-colors-set = true;
      cursor-foreground-color = "#282c34";
      cursor-background-color = "#abb2bf";
      highlight-colors-set = true;
      highlight-foreground-color = "#abb2bf";
      highlight-background-color = "#3e4451";
      audible-bell = false;
      scrollback-unlimited = true;
    };
  };

  home.packages = with pkgs; [
    gnome-terminal
  ];
}
