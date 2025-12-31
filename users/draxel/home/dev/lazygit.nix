# Lazygit - terminal UI for git
{ config, pkgs, ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          lightTheme = false;
          # One Dark Pro colors
          selectedLineBgColor = [ "#2d313b" ];
          selectedRangeBgColor = [ "#414858" ];
        };
        showCommandLog = false;
        showRandomTip = false;
        nerdFontsVersion = "3";
      };
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
      };
    };
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };
}
