# fzf - fuzzy finder
{ config, pkgs, lib, ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
      # One Dark Pro colors
      "--color=bg+:#2d313b,bg:#282c34,spinner:#61afef,hl:#e06c75"
      "--color=fg:#abb2bf,header:#e06c75,info:#c678dd,pointer:#61afef"
      "--color=marker:#98c379,fg+:#abb2bf,prompt:#c678dd,hl+:#e06c75"
    ];
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
  };
}
