# Lazygit - terminal UI for git
{ config, pkgs, colors, ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          lightTheme = false;
          # Colors from centralized palette
          selectedLineBgColor = [ colors.hex.bg2 ];
          selectedRangeBgColor = [ colors.hex.bg3 ];
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
