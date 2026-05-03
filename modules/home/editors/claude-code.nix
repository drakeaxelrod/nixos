# Claude Code configuration
{ config, pkgs, lib, ... }:

{
  # CLI tools commonly used by Claude — always on PATH
  home.packages = with pkgs; [
    poppler-utils      # pdftotext, pdfinfo
    jq                 # JSON processing
    # yq removed: conflicts with yq-go already installed elsewhere
    ripgrep            # rg (faster grep)
    fd                 # find replacement
    bat                # cat with syntax highlighting
    imagemagick        # image operations
    ffmpeg             # video/audio
    curl               # HTTP
    wget               # downloads
    unzip
    zip
    tree
    htop
    fzf
  ];

  programs.claude-code = {
    enable = true;
    settings = {
      includeCoAuthoredBy = false;

      env = {
        DISABLE_TELEMETRY = "1";
        DISABLE_ERROR_REPORTING = "1";
        DISABLE_FEEDBACK_COMMAND = "1";
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      };

      cleanupPeriodDays = 7;

      permissions = {
        additionalDirectories = [ ];
        allow = [
          "WebFetch"
          "WebSearch"
          "Read"
          "Glob"
          "Grep"
          "Bash(ls:*)"
          "Bash(cat:*)"
          "Bash(head:*)"
          "Bash(tail:*)"
          "Bash(wc:*)"
          "Bash(find:*)"
          "Bash(file:*)"
          "Bash(which:*)"
          "Bash(echo:*)"
          "Bash(pwd)"
          "Bash(stat:*)"
          "Bash(tree:*)"
          "Bash(jq:*)"
          "Bash(yq:*)"
          "Bash(rg:*)"
          "Bash(fd:*)"
          "Bash(bat:*)"
          "Bash(pdftotext:*)"
          "Bash(pdfinfo:*)"
          "Bash(unzip -l:*)"
          "Bash(git status:*)"
          "Bash(git diff:*)"
          "Bash(git log:*)"
          "Bash(git show:*)"
          "Bash(git branch:*)"
          "Bash(git remote:*)"
          "Bash(git ls-files:*)"
          "Bash(git rev-parse:*)"
          "Bash(nix-shell -p *:*)"
          "Bash(nix --version)"
          "Bash(nix-shell --version)"
          "Bash(nix-store --query *:*)"
        ];
        deny = [
          "Bash(rm -rf:*)"
          "Bash(git push --force:*)"
          "Bash(git push -f:*)"
          "Bash(git reset --hard:*)"
          "Bash(sudo:*)"
          "Bash(nix-env -i:*)"
          "Bash(nix-env --install:*)"
          "Bash(nix-env -u:*)"
          "Bash(nix-env --upgrade:*)"
          "Bash(nix-collect-garbage:*)"
          "Bash(nix-store --gc:*)"
          "Bash(nix-store --delete:*)"
          "Bash(nix profile install:*)"
          "Bash(nix profile remove:*)"
          "Bash(nix profile rollback:*)"
          "Bash(nixos-rebuild *:*)"
          "Bash(nix flake update:*)"
        ];
        disableBypassPermissionsMode = "disable";
      };

      statusLine = {
        command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')]  $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
        padding = 0;
        type = "command";
      };
      theme = "dark";

      marketplaces = [
        {
          name = "claude-plugins-official";
          type = "github";
          url = "anthropics/claude-plugins-official";
        }
        {
          name = "superpowers-marketplace";
          type = "github";
          url = "obra/superpowers-marketplace";
        }
      ];

      enabledPlugins = {
        "context7@claude-plugins-official" = true;
        "superpowers@claude-plugins-official" = true;
      };
    };
  };
}