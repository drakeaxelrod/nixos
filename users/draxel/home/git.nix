# Git configuration
{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    # userEmail = "your@email.com";  # Set via SOPS or manually

    settings = {
      user.name = "draxel";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        lg = "log --oneline --graph --decorate";
      };
    };
  };
}
