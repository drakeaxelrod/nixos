# Font packages and configuration
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Nerd Fonts (for terminal/editor)
    nerd-fonts.lilex
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    nerd-fonts.hack

    # Sans-serif (UI fonts)
    inter
    roboto
    work-sans
    lato
    source-sans

    # Icons
    font-awesome

    # Emoji
    noto-fonts-color-emoji
    twemoji-color-font

    # CJK support
    noto-fonts-cjk-sans

    # General system fonts
    dejavu_fonts
    liberation_ttf
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Lilex Nerd Font Mono" "JetBrains Mono Nerd Font" "Noto Color Emoji" ];
      sansSerif = [ "Inter" "Noto Color Emoji" ];
      serif = [ "DejaVu Serif" "Noto Color Emoji" ];
      emoji = [ "Noto Color Emoji" "Twemoji" ];
    };
  };
}
