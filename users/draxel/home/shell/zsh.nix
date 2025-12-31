# Zsh shell configuration with advanced features
{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    # dotDir is relative to $HOME, use .config/zsh
    # History is stored separately in xdg.dataHome
    dotDir = "${config.xdg.configHome}/zsh";

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

      # NixOS
      #rebuild = "sudo nixos-rebuild switch --flake /etc/nixos";
      #rebuild-boot = "sudo nixos-rebuild boot --flake /etc/nixos";
      #rebuild-test = "sudo nixos-rebuild test --flake /etc/nixos";
      #update = "nix flake update /etc/nixos";
      #gc = "sudo nix-collect-garbage -d && nix-collect-garbage -d";

      # Git (additional to git plugin)
      gs = "git status";
      gd = "git diff";
      gds = "git diff --staged";
      gco = "git commit";
      gca = "git commit --amend";
      gp = "git push";
      gpl = "git pull";
      gl = "git log --oneline --graph --decorate -10";
      gla = "git log --oneline --graph --decorate --all";
      lg = "lazygit";

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

    initContent = ''
      # ============ Keybindings ============ #
      bindkey -e  # Emacs keybindings
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line
      bindkey '^[[3~' delete-char
      bindkey '^[[1;5C' forward-word   # Ctrl+Right
      bindkey '^[[1;5D' backward-word  # Ctrl+Left
      bindkey -M menuselect '^[[Z' reverse-menu-complete
      bindkey "^Xa" _expand_alias

      # ============ Completion Styles ============ #
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

      # ============ Directory Shortcuts ============ #
      hash -d work=/work
      hash -d proj=~/Projects
      hash -d nix=/etc/nixos
      hash -d config=~/.config

      # ============ Terminal Integration ============ #
      # Shell integration for terminal emulators (VSCode, etc.)
      if [[ "$TERM_PROGRAM" == "vscode" ]]; then
        . "$(code --locate-shell-integration-path zsh 2>/dev/null)" 2>/dev/null || true
      fi
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"              # ESC ESC to add sudo
        "docker"
        "systemd"
        "command-not-found"
        "colored-man-pages"
        "extract"           # Extract any archive with 'x'
        "z"                 # Jump to directories
        "per-directory-history"  # Ctrl+G to toggle
      ];
    };

    # Additional plugins via antidote
    antidote = {
      enable = true;
      plugins = [
        "zsh-users/zsh-completions"
        "jeffreytse/zsh-vi-mode"
      ];
    };
  };
}
