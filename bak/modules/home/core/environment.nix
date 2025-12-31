# XDG-compliant environment variables
{ config, pkgs, lib, ... }:

{
  home.sessionVariables = {
    # ==========================================================================
    # XDG Base Directories (already set by xdg.nix, but explicit for tools)
    # ==========================================================================

    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
    XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
    XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";

    # ==========================================================================
    # Editor / Pager
    # ==========================================================================

    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
    GIT_EDITOR = "nvim";
    PAGER = "less";
    MANPAGER = "nvim +Man!";

    # ==========================================================================
    # Terminal
    # ==========================================================================

    TERM = "xterm-256color";
    COLORTERM = "truecolor";

    # ==========================================================================
    # History Files (keep out of home)
    # ==========================================================================

    LESSHISTFILE = "${config.home.homeDirectory}/.cache/less/history";
    HISTFILE = "${config.home.homeDirectory}/.cache/zsh/history";
    MYSQL_HISTFILE = "${config.home.homeDirectory}/.cache/mysql_history";
    SQLITE_HISTORY = "${config.home.homeDirectory}/.cache/sqlite_history";

    # ==========================================================================
    # Development Tools (XDG compliance)
    # ==========================================================================

    # Rust
    CARGO_HOME = "${config.home.homeDirectory}/.local/share/cargo";
    RUSTUP_HOME = "${config.home.homeDirectory}/.local/share/rustup";

    # Go
    GOPATH = "${config.home.homeDirectory}/.local/share/go";
    GOMODCACHE = "${config.home.homeDirectory}/.cache/go/pkg/mod";

    # Node.js/NPM
    NPM_CONFIG_USERCONFIG = "${config.home.homeDirectory}/.config/npm/npmrc";
    NPM_CONFIG_CACHE = "${config.home.homeDirectory}/.cache/npm";
    NODE_REPL_HISTORY = "${config.home.homeDirectory}/.cache/node_repl_history";
    PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";

    # Python
    PYTHONSTARTUP = "${config.home.homeDirectory}/.config/python/startup.py";
    PYTHON_HISTORY = "${config.home.homeDirectory}/.cache/python/history";
    PYTHONPYCACHEPREFIX = "${config.home.homeDirectory}/.cache/python";
    PYTHONUSERBASE = "${config.home.homeDirectory}/.local/share/python";
    JUPYTER_CONFIG_DIR = "${config.home.homeDirectory}/.config/jupyter";
    IPYTHONDIR = "${config.home.homeDirectory}/.config/ipython";

    # Java
    _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=${config.home.homeDirectory}/.config/java";

    # Docker
    DOCKER_CONFIG = "${config.home.homeDirectory}/.config/docker";

    # ==========================================================================
    # Application Config Paths
    # ==========================================================================

    # GNU utilities
    WGETRC = "${config.home.homeDirectory}/.config/wgetrc";
    INPUTRC = "${config.home.homeDirectory}/.config/readline/inputrc";

    # GPG
    GNUPGHOME = "${config.home.homeDirectory}/.config/gnupg";

    # CUDA (NVIDIA)
    CUDA_CACHE_PATH = "${config.home.homeDirectory}/.cache/nv";

    # less
    LESS = "-R -F -g -i -M -S -w -X -z-4";

    # fzf (enhanced)
    FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
    FZF_CTRL_T_COMMAND = "fd --type f --hidden --follow --exclude .git";
    FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git";

    # bat
    BAT_THEME = "OneHalfDark";

    # ripgrep
    RIPGREP_CONFIG_PATH = "${config.home.homeDirectory}/.config/ripgrep/config";

    # ==========================================================================
    # Nix
    # ==========================================================================

    NIXPKGS_ALLOW_UNFREE = "1";
    NIX_AUTO_RUN = "1";
  };

  # ==========================================================================
  # PATH additions
  # ==========================================================================

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.local/share/cargo/bin"
    "${config.home.homeDirectory}/.local/share/go/bin"
    "${config.home.homeDirectory}/.local/share/pnpm"
  ];

  # ==========================================================================
  # Ensure cache directories exist
  # ==========================================================================

  home.activation.createCacheDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.cache/less
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.cache/zsh
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.cache/python
  '';
}
