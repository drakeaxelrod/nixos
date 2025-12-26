# Git configuration
{ config, pkgs, lib, ... }:

let
  cfg = config.custom.programs.git;
in
{
  options.custom.programs.git = {
    userName = lib.mkOption {
      type = lib.types.str;
      default = "Your Name";
      description = "Git user name";
    };
    userEmail = lib.mkOption {
      type = lib.types.str;
      default = "you@example.com";
      description = "Git user email";
    };
  };

  config = {
    programs.git = {
      enable = true;

      settings = {
        user = {
          name = cfg.userName;
          email = cfg.userEmail;
        };

        # Core settings
        core = {
          editor = "nvim";
          autocrlf = "input";
          whitespace = "fix";
        };

        # Merge/diff settings
        merge = {
          conflictstyle = "diff3";
          tool = "nvim";
        };
        diff.colorMoved = "default";

        # Branch settings
        init.defaultBranch = "main";
        pull.rebase = true;
        push = {
          autoSetupRemote = true;
          default = "current";
        };
        fetch.prune = true;

        # Rebase settings
        rebase = {
          autoStash = true;
          autoSquash = true;
        };

        # URL shortcuts
        url = {
          "git@github.com:" = {
            insteadOf = "gh:";
          };
          "git@gitlab.com:" = {
            insteadOf = "gl:";
          };
        };

        # Safe directories
        safe.directory = [
          "/etc/nixos"
        ];

        # Aliases
        alias = {
          # Status
          s = "status -sb";
          st = "status";

          # Branching
          br = "branch";
          bra = "branch -a";
          brd = "branch -d";
          brD = "branch -D";
          co = "checkout";
          cob = "checkout -b";
          sw = "switch";
          swc = "switch -c";

          # Commits
          ci = "commit";
          cia = "commit --amend";
          cian = "commit --amend --no-edit";
          cm = "commit -m";

          # Diff
          d = "diff";
          ds = "diff --staged";
          dt = "difftool";

          # Log
          lg = "log --oneline --graph --decorate";
          lga = "log --oneline --graph --decorate --all";
          ll = "log --pretty=format:'%C(yellow)%h%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' -20";
          last = "log -1 HEAD --stat";

          # Push/Pull
          p = "push";
          pf = "push --force-with-lease";
          pl = "pull";

          # Stash
          ss = "stash";
          sp = "stash pop";
          sl = "stash list";

          # Reset
          unstage = "reset HEAD --";
          uncommit = "reset --soft HEAD~1";
          discard = "checkout --";

          # Misc
          aliases = "config --get-regexp alias";
          contributors = "shortlog -sn";
          whoami = "config user.email";
        };

        # Colors
        color = {
          ui = "auto";
          branch = {
            current = "yellow bold";
            local = "green bold";
            remote = "cyan bold";
          };
          diff = {
            meta = "yellow bold";
            frag = "magenta bold";
            old = "red bold";
            new = "green bold";
          };
          status = {
            added = "green bold";
            changed = "yellow bold";
            untracked = "red bold";
          };
        };
      };
    };

    # Delta - better git diffs
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "One Dark";
      };
    };

    home.packages = with pkgs; [
      git-crypt      # Encrypt files in git
      git-lfs        # Large file support
    ];
  };
}
