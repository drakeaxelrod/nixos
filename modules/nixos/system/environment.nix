# System-wide Environment Variables
# XDG Base Directory compliant paths for all users and sessions
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.environment;
in
{
  options.modules.system.environment = {
    enable = lib.mkEnableOption "XDG-compliant environment variables";

    defaultEditor = lib.mkOption {
      type = lib.types.str;
      default = "nvim";
      description = "Default system editor";
    };

    defaultBrowser = lib.mkOption {
      type = lib.types.str;
      default = "firefox";
      description = "Default web browser";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.variables = {
      # ═══════════════════════════════════════════════════════════════════════
      # LOCALE & ENCODING
      # ═══════════════════════════════════════════════════════════════════════
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      # ═══════════════════════════════════════════════════════════════════════
      # DEFAULT APPLICATIONS
      # ═══════════════════════════════════════════════════════════════════════
      EDITOR = cfg.defaultEditor;
      VISUAL = cfg.defaultEditor;
      SUDO_EDITOR = cfg.defaultEditor;
      GIT_EDITOR = cfg.defaultEditor;
      BROWSER = cfg.defaultBrowser;

      # ═══════════════════════════════════════════════════════════════════════
      # TERMINAL
      # ═══════════════════════════════════════════════════════════════════════
      COLORTERM = "truecolor";

      # ═══════════════════════════════════════════════════════════════════════
      # PAGER (Less)
      # ═══════════════════════════════════════════════════════════════════════
      PAGER = "less";
      MANPAGER = "${cfg.defaultEditor} +Man!";
      LESSHISTFILE = "/dev/null";
      # -F: Quit if one screen       -g: Highlight last search only
      # -i: Case-insensitive search  -M: Verbose prompt
      # -R: ANSI color support       -S: Chop long lines
      # -w: Highlight first new line -X: No termcap init
      # -z-4: Scroll 4 lines less than screen height
      LESS = "-F -g -i -M -R -S -w -X -z-4";

      # ═══════════════════════════════════════════════════════════════════════
      # XDG - TERMINAL & SHELL TOOLS
      # ═══════════════════════════════════════════════════════════════════════
      BAT_CONFIG_PATH = "$HOME/.config/bat/config";
      STARSHIP_CONFIG = "$HOME/.config/starship.toml";
      SCREENRC = "$HOME/.config/screen/screenrc";
      INPUTRC = "$HOME/.config/readline/inputrc";

      # ═══════════════════════════════════════════════════════════════════════
      # XDG - GUI TOOLKITS
      # ═══════════════════════════════════════════════════════════════════════
      GTK2_RC_FILES = "$HOME/.config/gtk-2.0/gtkrc";
      KDEHOME = "$HOME/.config/kde";

      # ═══════════════════════════════════════════════════════════════════════
      # XDG - X11 & DISPLAY
      # ═══════════════════════════════════════════════════════════════════════
      XINITRC = "$HOME/.config/x11/xinitrc";
      XSERVERRC = "$HOME/.config/x11/xserverrc";
      ICEAUTHORITY = "$HOME/.cache/ICEauthority";

      # ═══════════════════════════════════════════════════════════════════════
      # XDG - SECURITY & ENCRYPTION
      # ═══════════════════════════════════════════════════════════════════════
      GNUPGHOME = "$HOME/.local/share/gnupg";
      PASSWORD_STORE_DIR = "$HOME/.local/share/pass";

      # ═══════════════════════════════════════════════════════════════════════
      # XDG - DEVELOPMENT TOOLS
      # ═══════════════════════════════════════════════════════════════════════
      DOCKER_CONFIG = "$HOME/.config/docker";
      WAKATIME_HOME = "$HOME/.local/share/wakatime";
      VSCODE_PORTABLE = "$HOME/.local/share/vscode";

      # ═══════════════════════════════════════════════════════════════════════
      # XDG - UTILITIES
      # ═══════════════════════════════════════════════════════════════════════
      WGETRC = "$HOME/.config/wget/wgetrc";
      TASKRC = "$HOME/.config/task/taskrc";
      TASKDATA = "$HOME/.local/share/task";
      NOTMUCH_CONFIG = "$HOME/.config/notmuch/notmuchrc";
      WEECHAT_HOME = "$HOME/.config/weechat";
      PARALLEL_HOME = "$HOME/.config/parallel";

      # ═══════════════════════════════════════════════════════════════════════
      # PYTHON
      # ═══════════════════════════════════════════════════════════════════════
      PYENV_ROOT = "$HOME/.local/share/pyenv";
      PYTHONSTARTUP = "$HOME/.config/python/pythonstartup.py";
      JUPYTER_CONFIG_DIR = "$HOME/.config/jupyter";
      JUPYTER_PLATFORM_DIRS = "1";
      IPYTHONDIR = "$HOME/.config/ipython";
      PYTHON_EGG_CACHE = "$HOME/.cache/python-eggs";
      CONDA_AUTO_ACTIVATE_BASE = "false";
      CONDA_PKGS_DIRS = "$HOME/.local/share/conda/pkgs";
      CONDA_ENVS_DIRS = "$HOME/.local/share/conda/envs";

      # ═══════════════════════════════════════════════════════════════════════
      # RUST
      # ═══════════════════════════════════════════════════════════════════════
      CARGO_HOME = "$HOME/.local/share/cargo";
      RUSTUP_HOME = "$HOME/.local/share/rustup";

      # ═══════════════════════════════════════════════════════════════════════
      # GO
      # ═══════════════════════════════════════════════════════════════════════
      GOPATH = "$HOME/.local/share/go";
      GOBIN = "$HOME/.local/share/go/bin";

      # ═══════════════════════════════════════════════════════════════════════
      # NODE.JS & JAVASCRIPT
      # ═══════════════════════════════════════════════════════════════════════
      NVM_DIR = "$HOME/.local/share/nvm";
      PNPM_HOME = "$HOME/.local/share/pnpm";
      NPM_CONFIG_USERCONFIG = "$HOME/.config/npm/npmrc";
      NPM_CONFIG_CACHE = "$HOME/.cache/npm";
      NPM_CONFIG_TMP = "$HOME/.cache/npm/tmp";
      NODE_REPL_HISTORY = "$HOME/.local/share/node_repl_history";
      NODE_REPL_HISTORY_SIZE = "1000";
      YARN_CACHE_FOLDER = "$HOME/.cache/yarn";

      # ═══════════════════════════════════════════════════════════════════════
      # RUBY
      # ═══════════════════════════════════════════════════════════════════════
      GEM_HOME = "$HOME/.local/share/gem";
      GEM_SPEC_CACHE = "$HOME/.cache/gem";
      BUNDLE_USER_CONFIG = "$HOME/.config/bundle";
      BUNDLE_USER_CACHE = "$HOME/.cache/bundle";
      BUNDLE_USER_PLUGIN = "$HOME/.local/share/bundle";
      IRBRC = "$HOME/.config/irb/irbrc";

      # ═══════════════════════════════════════════════════════════════════════
      # PHP
      # ═══════════════════════════════════════════════════════════════════════
      PHPRC = "$HOME/.config/php";
      PHP_INI_SCAN_DIR = "$HOME/.config/php/conf.d";
      COMPOSER_HOME = "$HOME/.config/composer";
      COMPOSER_CACHE_DIR = "$HOME/.cache/composer";

      # ═══════════════════════════════════════════════════════════════════════
      # PERL
      # ═══════════════════════════════════════════════════════════════════════
      PERL5LIB = "$HOME/.local/share/perl5/lib/perl5";
      PERL_LOCAL_LIB_ROOT = "$HOME/.local/share/perl5";

      # ═══════════════════════════════════════════════════════════════════════
      # R
      # ═══════════════════════════════════════════════════════════════════════
      R_ENVIRON_USER = "$HOME/.config/R/Renviron";
      R_PROFILE_USER = "$HOME/.config/R/Rprofile";
      R_LIBS_USER = "$HOME/.local/share/R/library";
      R_HISTFILE = "$HOME/.local/share/R/history";

      # ═══════════════════════════════════════════════════════════════════════
      # HASKELL
      # ═══════════════════════════════════════════════════════════════════════
      GHCUP_USE_XDG_DIRS = "1";
      STACK_XDG = "1";
      CABAL_CONFIG = "$HOME/.config/cabal/config";
      CABAL_DIR = "$HOME/.local/share/cabal";

      # ═══════════════════════════════════════════════════════════════════════
      # C/C++
      # ═══════════════════════════════════════════════════════════════════════
      GCC_COLORS = "error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";

      # ═══════════════════════════════════════════════════════════════════════
      # NEOVIM
      # ═══════════════════════════════════════════════════════════════════════
      TREE_SITTER_DIR = "$HOME/.config/tree-sitter";
      NVIM_PYTHON_LOG_FILE = "$HOME/.cache/nvim/pylog";

      # ═══════════════════════════════════════════════════════════════════════
      # CUDA & GPU
      # ═══════════════════════════════════════════════════════════════════════
      CUDA_CACHE_PATH = "$HOME/.cache/nv";

      # ═══════════════════════════════════════════════════════════════════════
      # DATABASES
      # ═══════════════════════════════════════════════════════════════════════
      MYSQL_HISTFILE = "$HOME/.local/share/mysql_history";
      PSQL_HISTORY = "$HOME/.local/share/psql_history";
      SQLITE_HISTORY = "$HOME/.local/share/sqlite_history";
      REDISCLI_HISTFILE = "$HOME/.local/share/redis_history";
      PGPASSFILE = "$HOME/.config/pg/pgpass";
      PGSERVICEFILE = "$HOME/.config/pg/pg_service.conf";

      # ═══════════════════════════════════════════════════════════════════════
      # DEVOPS & INFRASTRUCTURE
      # ═══════════════════════════════════════════════════════════════════════
      ANSIBLE_HOME = "$HOME/.config/ansible";
      ANSIBLE_CONFIG = "$HOME/.config/ansible/ansible.cfg";
      ANSIBLE_GALAXY_CACHE_DIR = "$HOME/.cache/ansible/galaxy_cache";
      AWS_SHARED_CREDENTIALS_FILE = "$HOME/.config/aws/credentials";
      AWS_CONFIG_FILE = "$HOME/.config/aws/config";
      KUBECONFIG = "$HOME/.config/kube/config";
      TF_CLI_CONFIG_FILE = "$HOME/.config/terraform/terraformrc";

      # ═══════════════════════════════════════════════════════════════════════
      # VIRTUALIZATION & CONTAINERS
      # ═══════════════════════════════════════════════════════════════════════
      VAGRANT_HOME = "$HOME/.local/share/vagrant";
      MINIKUBE_HOME = "$HOME/.local/share/minikube";
      WINEPREFIX = "$HOME/.local/share/wine";
    };

    # Ensure XDG base directories are set at the system level
    environment.sessionVariables = {
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_BIN_HOME = "$HOME/.local/bin";
    };
  };
}
