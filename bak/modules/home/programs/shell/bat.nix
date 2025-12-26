# bat - cat replacement with syntax highlighting
{ config, pkgs, lib, ... }:

{
  programs.bat = {
    enable = true;
    config = {
      theme = "One Dark";
      style = "numbers,changes,header";
    };
    themes = {
      "One Dark" = {
        src = pkgs.fetchFromGitHub {
          owner = "andresmichel";
          repo = "one-dark-theme";
          rev = "master";
          sha256 = "sha256-lx4FozdJrSRmFy19rpUkWPbFAikPxUUjpymEMtN2qAA=";
        };
        file = "One Dark.tmTheme";
      };
    };
  };
}
