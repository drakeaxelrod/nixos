# Starship Prompt Configuration
# Enhanced with Nerd Fonts & OneDarkPro colors
{ config, pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # ════════════════════════════════════════════════════════════════════════
      # PROMPT FORMAT
      # ════════════════════════════════════════════════════════════════════════

      # Main prompt - Clean two-line format
      # Line 1: Location + languages/tools
      # Line 2: Just the prompt character
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_status"
        "$python"
        "$nodejs"
        "$rust"
        "$golang"
        "$java"
        "$ruby"
        "$php"
        "$c"
        "$lua"
        "$elixir"
        "$package"
        "$docker_context"
        "$kubernetes"
        "$terraform"
        "$aws"
        "$gcloud"
        "$nix_shell"
        "$conda"
        "$cmd_duration"
        "$jobs"
        "\n"
        "$character"
      ];

      right_format = "";
      continuation_prompt = "[󰜴](bold bright-black) ";
      scan_timeout = 30;
      command_timeout = 1000;
      add_newline = false;

      # ════════════════════════════════════════════════════════════════════════
      # PROMPT CHARACTER
      # ════════════════════════════════════════════════════════════════════════

      character = {
        format = "$symbol";
        success_symbol = "[❯](bold purple)[❯](bold cyan)[❯](bold green) ";
        error_symbol = "[❯](bold red)[❯](bold yellow)[❯](bold red) ";
        vimcmd_symbol = "[❮](bold purple)[❮](bold cyan)[❮](bold green) ";
        vimcmd_visual_symbol = "[❮](bold yellow)[❮](bold magenta)[❮](bold yellow) ";
        vimcmd_replace_symbol = "[❮](bold red)[❮](bold yellow)[❮](bold red) ";
        disabled = false;
      };

      # ════════════════════════════════════════════════════════════════════════
      # CORE MODULES
      # ════════════════════════════════════════════════════════════════════════

      username = {
        format = "[$user]($style)[@](bold white)";
        style_root = "bold red";
        style_user = "bold cyan";
        show_always = false;
        disabled = false;
      };

      hostname = {
        ssh_only = true;
        ssh_symbol = "󰣀";
        trim_at = ".";
        format = "[$ssh_symbol$hostname]($style) ";
        style = "bold blue";
        disabled = false;
      };

      os = {
        format = "[$symbol ]($style)";
        style = "bold blue";
        disabled = true;  # Enable if you want OS icon in prompt
        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          AlmaLinux = " ";
          Amazon = " ";
          Android = " ";
          AOSC = " ";
          Arch = " ";
          Artix = " ";
          CachyOS = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Kali = " ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          Nobara = " ";
          OpenBSD = "󰈺 ";
          openSUSE = " ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          Redhat = " ";
          RedHatEnterprise = " ";
          RockyLinux = " ";
          Redox = "󰀘 ";
          Solus = "󰠳 ";
          SUSE = " ";
          Ubuntu = " ";
          Unknown = " ";
          Void = " ";
          Windows = "󰍲 ";
        };
      };

      directory = {
        format = "[$path]($style)[$read_only]($read_only_style) ";
        style = "bold cyan";
        read_only = " 󰌾";
        read_only_style = "bold red";
        truncation_length = 3;
        truncation_symbol = "…/";
        truncate_to_repo = false;
        repo_root_style = "bold purple";
        repo_root_format = "[$before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
        home_symbol = "~";
        use_os_path_sep = true;
        use_logical_path = true;
        disabled = false;
      };

      # ════════════════════════════════════════════════════════════════════════
      # GIT MODULES
      # ════════════════════════════════════════════════════════════════════════

      git_branch = {
        format = "\\[[$symbol$branch(:$remote_branch)]($style)\\]";
        symbol = "";
        style = "bold white";
        truncation_length = 30;
        truncation_symbol = "…";
        only_attached = false;
        always_show_remote = false;
        disabled = false;
      };

      git_commit = {
        commit_hash_length = 7;
        format = "[\\($hash$tag\\) ]($style)";
        style = "bold green";
        only_detached = true;
        disabled = false;
        tag_symbol = "󰓹";
        tag_disabled = false;
      };

      git_state = {
        rebase = "󰜘";
        merge = "󰘬";
        revert = "";
        cherry_pick = "";
        bisect = "";
        am = "󰁕";
        am_or_rebase = "󰁕";
        style = "bold yellow";
        format = "[$state($progress_current/$progress_total) ]($style)";
        disabled = false;
      };

      git_metrics = {
        added_style = "bold green";
        deleted_style = "bold red";
        only_nonzero_diffs = true;
        format = "([+$added]($added_style))([-$deleted]($deleted_style))";
        disabled = true;
        ignore_submodules = false;
      };

      git_status = {
        format = "([\\[$all_status$ahead_behind\\]]($style) )";
        style = "";
        conflicted = "[=$count](bold red)";
        ahead = "[⇡$count](bold green)";
        behind = "[⇣$count](bold red)";
        diverged = "[⇡$ahead_count⇣$behind_count](bold yellow)";
        up_to_date = "";
        untracked = "[?$count](bold blue)";
        stashed = "[*$count](bold cyan)";
        modified = "[!$count](bold yellow)";
        staged = "[+$count](bold green)";
        renamed = "[~$count](bold purple)";
        deleted = "[✘$count](bold red)";
        ignore_submodules = false;
        disabled = false;
      };

      # ════════════════════════════════════════════════════════════════════════
      # CLOUD & INFRASTRUCTURE
      # ════════════════════════════════════════════════════════════════════════

      aws = {
        format = "[on $symbol$profile(\\($region\\)) ]($style)";
        symbol = "";
        style = "bold yellow";
        disabled = false;
      };

      azure = {
        format = "[on $symbol$subscription ]($style)";
        symbol = "󰠅";
        style = "bold blue";
        disabled = true;
      };

      gcloud = {
        format = "[on $symbol$account(@$domain)(\\($region\\)) ]($style)";
        symbol = "󱇶";
        style = "bold blue";
        disabled = false;
      };

      docker_context = {
        format = "[via $symbol$context ]($style)";
        symbol = "";
        style = "bold blue";
        only_with_files = true;
        disabled = false;
        detect_files = [ "docker-compose.yml" "docker-compose.yaml" "Dockerfile" ];
      };

      kubernetes = {
        format = "[via $symbol$context(\\($namespace\\)) ]($style)";
        symbol = "󱃾";
        style = "bold cyan";
        disabled = true;
      };

      terraform = {
        format = "[via $symbol$workspace ]($style)";
        symbol = "󱁢";
        style = "bold purple";
        disabled = false;
        detect_extensions = [ "tf" "tfplan" "tfstate" ];
        detect_folders = [ ".terraform" ];
      };

      # ════════════════════════════════════════════════════════════════════════
      # PROGRAMMING LANGUAGES
      # ════════════════════════════════════════════════════════════════════════

      python = {
        format = "[via \${symbol}$version(\\($virtualenv\\))]($style) ";
        symbol = " ";
        style = "bold yellow";
        pyenv_version_name = false;
        pyenv_prefix = "pyenv ";
        python_binary = [ "python" "python3" "python2" ];
        detect_extensions = [ "py" ];
        detect_files = [
          "requirements.txt"
          ".python-version"
          "pyproject.toml"
          "Pipfile"
          "tox.ini"
          "setup.py"
          "__init__.py"
        ];
        disabled = false;
      };

      nodejs = {
        format = "[via \${symbol}$version ]($style)";
        symbol = " ";
        style = "bold green";
        detect_extensions = [ "js" "mjs" "cjs" "ts" "mts" "cts" ];
        detect_files = [ "package.json" ".node-version" ".nvmrc" ];
        detect_folders = [ "node_modules" ];
        disabled = false;
      };

      rust = {
        format = "[via \${symbol}$version ]($style)";
        symbol = " ";
        style = "bold red";
        detect_extensions = [ "rs" ];
        detect_files = [ "Cargo.toml" "Cargo.lock" ];
        disabled = false;
      };

      golang = {
        format = "[via \${symbol}$version ]($style)";
        symbol = " ";
        style = "bold cyan";
        detect_extensions = [ "go" ];
        detect_files = [ "go.mod" "go.sum" "go.work" ".go-version" ];
        detect_folders = [ "Godeps" ];
        disabled = false;
      };

      java = {
        format = "[via \${symbol}$version ]($style)";
        symbol = " ";
        style = "bold red";
        detect_extensions = [ "java" "class" "jar" "gradle" "clj" "cljc" ];
        detect_files = [ "pom.xml" "build.gradle.kts" "build.sbt" ".java-version" ];
        disabled = false;
      };

      kotlin = {
        format = "[via \${symbol}$version ]($style)";
        symbol = " ";
        style = "bold blue";
        detect_extensions = [ "kt" "kts" ];
        disabled = false;
      };

      ruby = {
        format = "[via \${symbol}$version ]($style)";
        symbol = " ";
        style = "bold red";
        detect_extensions = [ "rb" ];
        detect_files = [ "Gemfile" ".ruby-version" ];
        disabled = false;
      };

      php = {
        format = "[via \${symbol}$version ]($style)";
        symbol = "󰌟 ";
        style = "bold purple";
        detect_extensions = [ "php" ];
        detect_files = [ "composer.json" ".php-version" ];
        disabled = false;
      };

      lua = {
        format = "[via \${symbol}$version ]($style)";
        symbol = " ";
        style = "bold blue";
        detect_extensions = [ "lua" ];
        detect_files = [ ".lua-version" ];
        detect_folders = [ "lua" ];
        disabled = false;
      };

      c = {
        format = "[via \${symbol}$version ]($style)";
        symbol = " ";
        style = "bold blue";
        detect_extensions = [ "c" "h" ];
        disabled = false;
      };

      elixir = {
        format = "[via \${symbol}$version ]($style)";
        symbol = " ";
        style = "bold purple";
        detect_extensions = [];
        detect_files = [ "mix.exs" ];
        disabled = false;
      };

      erlang = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold red";
        detect_files = [ "rebar.config" "erlang.mk" ];
        disabled = false;
      };

      haskell = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold purple";
        detect_extensions = [ "hs" "cabal" "hs-boot" ];
        detect_files = [ "stack.yaml" "cabal.project" ];
        disabled = false;
      };

      julia = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold purple";
        detect_extensions = [ "jl" ];
        detect_files = [ "Project.toml" "Manifest.toml" ];
        disabled = false;
      };

      scala = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold red";
        detect_extensions = [ "sbt" "scala" ];
        detect_files = [ ".scalaenv" ".sbtenv" "build.sbt" ];
        disabled = false;
      };

      swift = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold 208";  # Orange
        detect_extensions = [ "swift" ];
        detect_files = [ "Package.swift" ];
        disabled = false;
      };

      zig = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold yellow";
        detect_extensions = [ "zig" ];
        disabled = false;
      };

      dart = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold blue";
        detect_extensions = [ "dart" ];
        detect_files = [ "pubspec.yaml" "pubspec.yml" "pubspec.lock" ];
        disabled = false;
      };

      deno = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold green";
        detect_files = [ "deno.json" "deno.jsonc" "mod.ts" "deps.ts" ];
        disabled = false;
      };

      dotnet = {
        format = "[$symbol$version]($style) ";
        symbol = "󰪮";
        style = "bold blue";
        detect_extensions = [ "csproj" "fsproj" "xproj" ];
        detect_files = [ "global.json" "project.json" "Directory.Build.props" ];
        disabled = false;
      };

      # ════════════════════════════════════════════════════════════════════════
      # PACKAGE MANAGERS & TOOLS
      # ════════════════════════════════════════════════════════════════════════

      package = {
        format = "[is $symbol$version ]($style)";
        symbol = "󰏗";
        style = "bold yellow";
        display_private = false;
        disabled = false;
      };

      conda = {
        format = "[via $symbol$environment ]($style)";
        symbol = "";
        style = "bold green";
        ignore_base = true;
        disabled = false;
      };

      nix_shell = {
        format = "[via $symbol$state(\\($name\\)) ]($style)";
        symbol = "󱄅";
        style = "bold blue";
        impure_msg = "impure";
        pure_msg = "pure";
        disabled = false;
      };

      helm = {
        format = "[$symbol$version]($style) ";
        symbol = "󰷀";
        style = "bold white";
        detect_files = [ "helmfile.yaml" "Chart.yaml" ];
        disabled = false;
      };

      # ════════════════════════════════════════════════════════════════════════
      # SYSTEM & STATUS
      # ════════════════════════════════════════════════════════════════════════

      cmd_duration = {
        min_time = 2000;
        format = "[took $duration ]($style)";
        style = "bold yellow";
        show_milliseconds = false;
        show_notifications = false;
        min_time_to_notify = 45000;
        disabled = false;
      };

      jobs = {
        threshold = 1;
        symbol_threshold = 1;
        number_threshold = 2;
        format = "[$symbol×$number ]($style)";
        symbol = "";
        style = "bold blue";
        disabled = false;
      };

      battery = {
        format = "[$symbol$percentage]($style) ";
        full_symbol = "󰁹";
        charging_symbol = "󰂄";
        discharging_symbol = "󱟞";
        unknown_symbol = "󰂑";
        empty_symbol = "󰂎";
        disabled = false;
        display = [
          { threshold = 10; style = "bold red"; }
          { threshold = 30; style = "bold yellow"; }
        ];
      };

      memory_usage = {
        threshold = 75;
        format = "[$symbol$ram(|$swap)]($style) ";
        symbol = "󰍛";
        style = "bold white";
        disabled = true;
      };

      sudo = {
        format = "[$symbol]($style)";
        symbol = "󱑷";
        style = "bold red";
        allow_windows = false;
        disabled = false;
      };

      status = {
        format = "[$symbol$status]($style) ";
        symbol = "✖";
        success_symbol = "";
        not_executable_symbol = "";
        not_found_symbol = "󰍉";
        sigint_symbol = "󰒠";
        signal_symbol = "󱐋";
        style = "bold red";
        recognize_signal_code = true;
        disabled = true;
      };

      container = {
        format = "[$symbol\\[$name\\]]($style) ";
        symbol = "󰆧";
        style = "bold red dimmed";
        disabled = false;
      };

      shlvl = {
        threshold = 2;
        format = "[$symbol$shlvl]($style) ";
        symbol = "󰘍";
        repeat = false;
        style = "bold yellow";
        disabled = true;
      };

      # ════════════════════════════════════════════════════════════════════════
      # MISCELLANEOUS
      # ════════════════════════════════════════════════════════════════════════

      line_break.disabled = true;

      time = {
        format = "[$time]($style) ";
        style = "bold white";
        use_12hr = false;
        disabled = true;
        time_format = "%T";
      };

      localip = {
        ssh_only = true;
        format = "[$localipv4]($style) ";
        style = "bold yellow";
        disabled = true;
      };

      shell = {
        format = "[$indicator]($style) ";
        bash_indicator = "";
        fish_indicator = "󰈺";
        zsh_indicator = "";
        powershell_indicator = "󰨊";
        nu_indicator = "";
        unknown_indicator = "";
        style = "bold white";
        disabled = true;
      };

      # ════════════════════════════════════════════════════════════════════════
      # LESS COMMON LANGUAGES
      # ════════════════════════════════════════════════════════════════════════

      cmake = {
        format = "[$symbol$version]($style) ";
        symbol = "△";
        style = "bold blue";
        disabled = false;
      };

      buf = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold blue";
        disabled = false;
      };

      cobol = {
        format = "[$symbol$version]($style) ";
        symbol = "󰔷";
        style = "bold blue";
        disabled = false;
      };

      crystal = {
        format = "[$symbol$version]($style) ";
        symbol = "󰬯";
        style = "bold red";
        disabled = false;
      };

      elm = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold cyan";
        disabled = false;
      };

      nim = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold yellow";
        disabled = false;
      };

      ocaml = {
        format = "[$symbol$version(\\($switch_indicator$switch_name\\))]($style) ";
        symbol = "";
        style = "bold yellow";
        disabled = false;
      };

      perl = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold blue";
        disabled = false;
      };

      purescript = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold white";
        disabled = false;
      };

      red = {
        format = "[$symbol$version]($style) ";
        symbol = "󰔶";
        style = "bold red";
        disabled = false;
      };

      rlang = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold blue";
        disabled = false;
      };

      typst = {
        format = "[$symbol$version]($style) ";
        symbol = "";
        style = "bold cyan";
        detect_extensions = [ "typ" ];
        detect_files = [ "template.typ" ];
        disabled = false;
      };

      vagrant = {
        format = "[$symbol$version]($style) ";
        symbol = "󰗮";
        style = "bold cyan";
        disabled = false;
      };

      vlang = {
        format = "[$symbol$version]($style) ";
        symbol = "󰍛";
        style = "bold blue";
        disabled = false;
      };

      # ════════════════════════════════════════════════════════════════════════
      # SYMBOL-ONLY CONFIGS (Nerd Font symbols for detection)
      # ════════════════════════════════════════════════════════════════════════

      bun.symbol = " ";
      cpp.symbol = " ";
      fennel.symbol = " ";
      fortran.symbol = " ";
      fossil_branch.symbol = " ";
      gradle.symbol = " ";
      guix_shell.symbol = " ";
      haxe.symbol = " ";
      meson.symbol = "󰔷 ";
      pijul_channel.symbol = " ";
      pixi.symbol = "󰏗 ";
      xmake.symbol = " ";
      hg_branch.symbol = " ";

      # ════════════════════════════════════════════════════════════════════════
      # DISABLED MODULES
      # ════════════════════════════════════════════════════════════════════════

      openstack.disabled = true;
      pulumi.disabled = true;
      singularity.disabled = true;
      spack.disabled = true;
      vcsh.disabled = true;
    };
  };
}
