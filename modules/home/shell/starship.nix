# Starship prompt configuration
{ config, pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      add_newline = false;

      # Traditional style: user@host ~/path (git) $
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$nix_shell"
        "$python"
        "$nodejs"
        "$rust"
        "$golang"
        "$docker_context"
        "$cmd_duration"
        "$character"
      ];

      character = {
        success_symbol = " [\\$](bold green)";
        error_symbol = " [\\$](bold red)";
        vimcmd_symbol = " [](bold green)";
      };

      username = {
        show_always = true;
        style_user = "bold cyan";
        style_root = "bold red";
        format = "[$user]($style)";
      };

      hostname = {
        ssh_only = false;
        ssh_symbol = " ";
        style = "bold purple";
        format = "[@](bold yellow)[$hostname]($style) ";
      };

      os = {
        disabled = false;
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
        truncation_length = 5;
        truncate_to_repo = false;
        style = "bold blue";
        format = "[$path]($style)[$read_only]($read_only_style)";
        read_only = " 󰌾";
        read_only_style = "bold red";
        home_symbol = "~";
      };

      git_branch = {
        symbol = " ";
        style = "bold purple";
        format = " [$symbol\\($branch]($style)";
      };

      git_commit = {
        tag_symbol = "  ";
      };

      git_status = {
        style = "bold yellow";
        format = "[$all_status$ahead_behind]($style)[\\)](bold purple)";
        conflicted = "=";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        untracked = "?";
        stashed = "*";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "";
      };

      # Nerd font symbols
      aws.symbol = " ";
      buf.symbol = " ";
      bun.symbol = " ";
      c.symbol = " ";
      cpp.symbol = " ";
      cmake.symbol = " ";
      conda.symbol = " ";
      crystal.symbol = " ";
      dart.symbol = " ";
      deno.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      fennel.symbol = " ";
      fortran.symbol = " ";
      fossil_branch.symbol = " ";
      gcloud.symbol = " ";
      golang.symbol = " ";
      gradle.symbol = " ";
      guix_shell.symbol = " ";
      haskell.symbol = " ";
      haxe.symbol = " ";
      hg_branch.symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      kotlin.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      meson.symbol = "󰔷 ";
      nim.symbol = "󰆥 ";
      nodejs.symbol = " ";
      ocaml.symbol = " ";
      package.symbol = "󰏗 ";
      perl.symbol = " ";
      php.symbol = " ";
      pijul_channel.symbol = " ";
      pixi.symbol = "󰏗 ";
      python.symbol = " ";
      rlang.symbol = "󰟔 ";
      ruby.symbol = " ";
      rust.symbol = "󱘗 ";
      scala.symbol = " ";
      status.symbol = " ";
      swift.symbol = " ";
      xmake.symbol = " ";
      zig.symbol = " ";

      nix_shell = {
        symbol = " ";
        format = " [$symbol$state]($style)";
        style = "bold blue";
      };

      cmd_duration = {
        min_time = 5000;
        format = " [took $duration]($style)";
        style = "bold yellow";
      };

      docker_context = {
        symbol = " ";
        style = "bold blue";
        format = " [\\($symbol$context\\)]($style)";
      };
    };
  };
}
