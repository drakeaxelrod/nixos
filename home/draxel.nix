# Home Manager configuration
# Enable in flake.nix: home-manager.users.${vars.user.name} = import ./home/draxel.nix;

{ config, pkgs, inputs, ... }:

let
  vars = import ../vars.nix;
in
{
  home.username = vars.user.name;
  home.homeDirectory = "/home/${vars.user.name}";
  home.stateVersion = vars.stateVersion;

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # ==========================================================================
  # Packages (user-level)
  # ==========================================================================

  home.packages = with pkgs; [
    # CLI tools
    eza          # Modern ls
    bat          # Modern cat
    fzf          # Fuzzy finder
    zoxide       # Smart cd
    lazygit      # Git TUI
    jq           # JSON processor
    yq           # YAML processor

    # Development
    direnv
    nix-direnv

    # Security/Pentest
    # nmap
    # burpsuite  # Unfree, enable if needed
    # ghidra

    # Media
    # vlc
    # spotify

    # Communication
    # discord
    # slack
  ];

  # ==========================================================================
  # Zsh Configuration
  # ==========================================================================

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      ll = "eza -la";
      ls = "eza";
      la = "eza -a";
      lt = "eza --tree";
      cat = "bat";
      vim = "nvim";

      # NixOS
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#${vars.hostname}";
      update = "nix flake update /etc/nixos";
      gc = "sudo nix-collect-garbage -d";

      # Git
      gs = "git status";
      gd = "git diff";
      gco = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph --decorate -10";
      lg = "lazygit";

      # Safety
      rm = "rm -i";
      cp = "cp -i";
      mv = "mv -i";
    };

    initExtra = ''
      # Keybindings
      bindkey -e  # Emacs keybindings
      bindkey '^[[A' history-search-backward
      bindkey '^[[B' history-search-forward
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line
      bindkey '^[[3~' delete-char

      # Better completion
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

      # Prompt customization (simple, fast) - starship overrides this
      PROMPT='%F{cyan}%n@%m%f %F{blue}%~%f %F{green}$%f '

      # Work directory shortcut
      hash -d work=/work
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"           # ESC ESC to add sudo
        "docker"
        "systemd"
        "command-not-found"
      ];
      # theme = "robbyrussell";  # Using starship instead
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[>](bold red)";
      };
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };
      git_branch = {
        symbol = " ";
      };
      nix_shell = {
        symbol = " ";
        format = "via [$symbol$state]($style) ";
      };
    };
  };

  # ==========================================================================
  # Git Configuration
  # ==========================================================================

  programs.git = {
    enable = true;
    userName = vars.user.name;
    # userEmail = "your@email.com";  # Set your email

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };

    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      lg = "log --oneline --graph --decorate";
    };
  };

  # ==========================================================================
  # Neovim
  # ==========================================================================

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraConfig = ''
      set number
      set relativenumber
      set expandtab
      set tabstop=2
      set shiftwidth=2
      set smartindent
      set clipboard=unnamedplus
      set ignorecase
      set smartcase
      set termguicolors
    '';

    # Add plugins as needed
    # plugins = with pkgs.vimPlugins; [ ... ];
  };

  # ==========================================================================
  # GNOME Configuration
  # ==========================================================================

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };

    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "org.gnome.Terminal.desktop"
        "virt-manager.desktop"
        "discord.desktop"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>Return";
      command = "gnome-terminal";
      name = "Terminal";
    };
  };

  # ==========================================================================
  # XDG Directories
  # ==========================================================================

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
  };
}
