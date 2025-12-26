# System-level ZSH configuration with advanced options
{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    enableLsColors = true;
    histSize = 100000;

    setOptions = [
      # ===== General ===== #
      "CORRECT_ALL"              # Correct typos
      "AUTO_PUSHD"               # Make cd push old directory onto stack
      "CDABLE_VARS"              # Like AUTO_CD for named directories
      "PUSHD_IGNORE_DUPS"        # Don't push duplicates onto stack
      "NO_CASE_GLOB"             # Case insensitive globbing
      "NUMERIC_GLOB_SORT"        # Sort globs numerically (01 2 03 -> 01 02 03)
      "NOMATCH"                  # Error if glob has no matches
      "MENU_COMPLETE"            # Insert first match immediately
      "NO_LIST_AMBIGUOUS"        # Show completion menu for ambiguous
      "INTERACTIVE_COMMENTS"     # Allow comments in interactive mode
      "NO_BEEP"                  # Disable beep
      "NO_FLOW_CONTROL"          # Disable ^S/^Q flow control
      "ALWAYS_TO_END"            # Move cursor to end when completing
      "COMPLETE_ALIASES"         # Autocompletion for aliases

      # ===== History ===== #
      "EXTENDED_HISTORY"         # Write timestamps to history
      "APPEND_HISTORY"           # Append to history
      "HIST_EXPIRE_DUPS_FIRST"   # Trim duplicates first
      "HIST_FIND_NO_DUPS"        # Don't show dups when searching
      "HIST_IGNORE_DUPS"         # Don't add consecutive dups
      "HIST_IGNORE_SPACE"        # Don't add commands starting with space
      "HIST_REDUCE_BLANKS"       # Remove blank lines
      "HIST_VERIFY"              # Show history expansion before running
      "SHARE_HISTORY"            # Share history between sessions
    ];

    shellInit = ''
      # ============ Completion Styles ============ #

      # Include hidden files
      _comp_options+=(globdots)

      # Accept exact matches
      zstyle ':completion:*' accept-exact '*(N)'

      # Use cache
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

      # Squeeze slashes
      zstyle ':completion:*' squeeze-slashes yes

      # Menu-driven completion
      zstyle ':completion:*' menu select

      # Case-insensitive matching
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      # Verbose completion
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*' auto-description 'specify: %d'

      # Formatting
      zstyle ':completion:*:corrections' format '%F{red}%d (errors: %e)%f'
      zstyle ':completion:*:descriptions' format '%F{yellow}completing %B%d%b%f'
      zstyle ':completion:*:messages' format '%F{purple}%d%f'
      zstyle ':completion:*:warnings' format '%F{red}No matches for: %d%f'
      zstyle ':completion:*' group-name ""

      # Expand aliases on tab
      zstyle ':completion:*' completer _expand_alias _complete _ignored

      # Auto-rehash for new executables
      zstyle ':completion:*' rehash true

      # Kill completion with preview
      zstyle ':completion:*:*:kill:*' menu yes select
      zstyle ':completion:*:kill:*' force-list always

      # Ignore completion functions
      zstyle ':completion:*:functions' ignored-patterns '_*'
    '';

    promptInit = ''
      # Starship prompt (if available)
      if command -v starship &> /dev/null; then
        eval "$(starship init zsh)"
      fi
    '';
  };

  # System packages for shell enhancement
  environment.systemPackages = with pkgs; [
    starship
    lsd
    bat
    fzf
    ripgrep
    fd
    jq
    grc        # Generic colorizer
    fastfetch
    direnv
  ];
}
