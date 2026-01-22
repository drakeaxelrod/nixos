# Zsh shell configuration with advanced features
{ config, pkgs, lib, colors, ... }:

let
  # Custom plugins directory
  pluginsDir = ./plugins;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # Session variables (exported)
    sessionVariables = {
      KEYTIMEOUT = "1";  # Reduce ESC delay for vi-mode (10ms)
      ZSH_CACHE_DIR = "${config.xdg.cacheHome}/zsh";
    };

    # Local variables (not exported, zsh only)
    localVariables = {
      FORGIT_NO_ALIASES = "1";  # Disable forgit aliases to prevent conflicts
    };

    # Autosuggestions (gray text showing command predictions)
    autosuggestion = {
      enable = true;
      # Try history first, then completion engine
      strategy = [ "history" "completion" ];
      # Suggestion highlight color (gray, subtle)
      # highlight = "fg=#abb2bf,italic";
    };

    # Syntax highlighting (colorize commands as you type)
    syntaxHighlighting = {
      enable = true;
      # Enable additional highlighters
      highlighters = [
        "main"        # Base highlighting
        "brackets"    # Matching brackets
        "pattern"     # Custom patterns
        "cursor"      # Cursor highlighting
        "root"        # Highlight when root
      ];
      # Custom syntax styles (using centralized color palette)
      styles = {
        # Commands
        "command" = "fg=${colors.hex.green}";           # Green - valid commands
        "unknown-command" = "fg=${colors.hex.red}";     # Red - unknown commands
        "builtin" = "fg=${colors.hex.purple}";          # Purple - builtins
        "alias" = "fg=${colors.hex.blue}";              # Blue - aliases
        "function" = "fg=${colors.hex.blue}";           # Blue - functions
        # Paths and strings
        "path" = "fg=${colors.hex.yellow},underline";   # Yellow - paths
        "globbing" = "fg=${colors.hex.yellow}";         # Yellow - globs
        "single-quoted-argument" = "fg=${colors.hex.green}";  # Green - strings
        "double-quoted-argument" = "fg=${colors.hex.green}";  # Green - strings
        # Options and operators
        "single-hyphen-option" = "fg=${colors.hex.fg1}";
        "double-hyphen-option" = "fg=${colors.hex.fg1}";
        "redirection" = "fg=${colors.hex.cyan}";        # Cyan - redirects
        "commandseparator" = "fg=${colors.hex.purple}"; # Purple - ; && ||
        # Comments
        "comment" = "fg=${colors.hex.fg0},italic";      # Muted - comments
      };
    };

    # Completion styles (zstyle configuration)
    completionInit = ''
      # Include hidden files
      _comp_options+=(globdots)

      # Menu selection
      zstyle ':completion:*' menu select

      # Case-insensitive matching
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

      # Colorize completions
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

      # Formatting
      zstyle ':completion:*:corrections' format '%F{red}%d (errors: %e)%f'
      zstyle ':completion:*:descriptions' format '%F{yellow}completing %B%d%b%f'
      zstyle ':completion:*:messages' format '%F{purple}%d%f'
      zstyle ':completion:*:warnings' format '%F{red}No matches for: %d%f'
      zstyle ':completion:*' group-name ""

      # Expand aliases
      zstyle ':completion:*' completer _expand_alias _complete _ignored

      # Kill completion
      zstyle ':completion:*:*:kill:*' menu yes select
      zstyle ':completion:*:kill:*' force-list always

      # Cache
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

      # Auto-rehash for new executables
      zstyle ':completion:*' rehash true
    '';

    # dotDir is relative to $HOME, use .config/zsh
    # History is stored separately in xdg.dataHome
    dotDir = "${config.xdg.configHome}/zsh";

    # Vi keybindings
    defaultKeymap = "viins"; # null or one of "emacs", "vicmd", "viins"

    # Named directory hashes (~work, ~proj, etc.)
    dirHashes = {
      work = "/work";
      proj = "$HOME/Projects";
      nix = "/etc/nixos";
      config = "$HOME/.config";
    };

    # Zsh options
    setOptions = [
      "HIST_FCNTL_LOCK"       # Better history file locking
      "AUTO_PUSHD"            # Push directories to stack
      "PUSHD_IGNORE_DUPS"     # No duplicates in dir stack
      "PUSHD_SILENT"          # Don't print stack after pushd/popd
      "EXTENDED_GLOB"         # Extended globbing (#, ~, ^)
      "NO_BEEP"               # No beeping
      "INTERACTIVE_COMMENTS"  # Allow comments in interactive shell
      "RC_QUOTES"             # Allow '' inside single quotes
    ];

    history = {
      size = 1000000;
      save = 1000000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
      extended = true;  # Write timestamps
    };

    historySubstringSearch = {
      enable = true;
      searchDownKey = [ "^[[B" ];
      searchUpKey = [ "^[[A" ];
    };

    shellAliases = {
      # Modern CLI replacements
      cat = "bat";
      vim = "nvim";

      # lsd tree aliases (override default lt with depth limit)
      lt = lib.mkForce "lsd --tree --depth=2";
      lt1 = "lsd --tree --depth=1";
      lt2 = "lsd --tree --depth=2";
      lt3 = "lsd --tree --depth=3";

      # Safety
      rm = "rm -i";
      cp = "cp -i";
      mv = "mv -i";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";

      # Utilities
      cls = "clear";
      path = "echo $PATH | tr ':' '\\n'";
      fpath = "echo $FPATH | tr ':' '\\n'";
      ports = "sudo lsof -PiTCP -sTCP:LISTEN";
      timestamp = "date '+%Y-%m-%d_%H-%M-%S'";
      serve = "python3 -m http.server";
    };

    # Abbreviations (auto-expand as you type, before pressing enter)
    zsh-abbr = {
      enable = true;
      abbreviations = {
        # Git commands (expand in command position only)
        gs = "git status";
        gd = "git diff";
        gds = "git diff --staged";
        gco = "git commit";
        gca = "git commit --amend";
        gp = "git push";
        gpl = "git pull";
        gl = "git log --oneline --graph --decorate -10";
        gla = "git log --oneline --graph --decorate --all";
        ga = "git add";
        gaa = "git add --all";
        gb = "git branch";
        gch = "git checkout";
        gcl = "git clone";
        gf = "git fetch";
        gm = "git merge";
        gr = "git rebase";
        grs = "git reset";
        gst = "git stash";
        lg = "lazygit";
        gacp = "oco";
      };
    };

    # Global aliases (expanded anywhere on the line)
    shellGlobalAliases = {
      G = "| grep";
      L = "| less";
      H = "| head";
      T = "| tail";
      C = "| wc -l";
      J = "| jq";
      NE = "2>/dev/null";
      NUL = ">/dev/null 2>&1";
    };

    # Extra init content
    initContent = ''
      # GPG TTY for commit signing (must be set at runtime)
      export GPG_TTY=$(tty)

      # Keybindings (vi mode set via defaultKeymap)
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line
      bindkey '^[[3~' delete-char
      bindkey '^[[1;5C' forward-word   # Ctrl+Right
      bindkey '^[[1;5D' backward-word  # Ctrl+Left
      bindkey -M menuselect '^[[Z' reverse-menu-complete
      bindkey "^Xa" _expand_alias
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"                    # ESC ESC to add sudo
        "docker"
        "systemd"
        "command-not-found"
        "colored-man-pages"
        "extract"                 # Extract any archive with 'x'
        "z"                       # Jump to directories
        "per-directory-history"   # Ctrl+G to toggle
      ];
    };

    # Additional plugins via antidote
    antidote = {
      enable = true;
      plugins = [
        "zsh-users/zsh-completions"
        "jeffreytse/zsh-vi-mode"
        # Custom local plugins
        "${pluginsDir}/vscode.zsh"   # VS Code integration
        "${pluginsDir}/prompt.zsh"   # OSC 133 terminal integration
      ];
    };
  };
}
