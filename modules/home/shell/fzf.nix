# fzf - Fuzzy Finder
# Fast file and command searching with preview support
{ config, pkgs, lib, ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Default file search command (fd is faster than find)
    defaultCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";

    # Widget commands
    fileWidgetCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --strip-cwd-prefix --hidden --follow --exclude .git";

    # Trigger sequence for completion
    # Type ** and press Tab to activate
    # e.g., vim **<Tab>, cd **<Tab>
    # tmux = { enableShellIntegration = true; };  # If using tmux

    # Default options for all fzf invocations
    defaultOptions = [
      # Layout
      "--height=90%"
      "--layout=reverse"
      "--info=inline"
      "--border=rounded"
      "--ansi"
      "--multi"
      "--cycle"

      # Preview window
      "--preview-window=right:50%:wrap"

      # Keybindings - Preview navigation
      "--bind=ctrl-u:preview-page-up"
      "--bind=ctrl-d:preview-page-down"
      "--bind=ctrl-f:preview-down"
      "--bind=ctrl-b:preview-up"
      "--bind=shift-up:preview-page-up"
      "--bind=shift-down:preview-page-down"
      "--bind=ctrl-/:toggle-preview"

      # Keybindings - Selection
      "--bind=ctrl-space:toggle+down"
      "--bind=ctrl-a:select-all"
      "--bind=alt-enter:print-query"
      "--bind=change:first"

      # OneDarkPro colors
      "--color=fg:-1,bg:-1,hl:#61afef"
      "--color=fg+:#abb2bf,bg+:#3e4452,hl+:#61afef"
      "--color=info:#e5c07b,prompt:#61afef,pointer:#e06c75"
      "--color=marker:#98c379,spinner:#c678dd,header:#56b6c2"
      "--color=border:#5c6370,gutter:-1"
    ];

    # File widget options (Ctrl+T)
    fileWidgetOptions = [
      "--preview 'bat --style=numbers,changes --color=always --line-range :500 {} 2>/dev/null || cat {}'"
    ];

    # Change directory widget options (Alt+C)
    changeDirWidgetOptions = [
      "--preview 'lsd --tree --depth 2 --color=always {} 2>/dev/null || ls -la {}'"
    ];

    # History widget options (Ctrl+R)
    historyWidgetOptions = [
      "--preview 'echo {}'"
      "--preview-window down:3:wrap"
    ];
  };
}
