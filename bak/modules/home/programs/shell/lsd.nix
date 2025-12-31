# lsd - ls replacement with icons
{ config, pkgs, lib, ... }:

{
  programs.lsd = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      classic = false;
      blocks = [ "permission" "user" "group" "size" "date" "name" ];
      color = {
        when = "auto";
        theme = "default";
      };
      date = "relative";
      dereference = false;
      icons = {
        when = "auto";
        theme = "fancy";
        separator = " ";
      };
      layout = "grid";
      size = "default";
      sorting = {
        column = "name";
        reverse = false;
        dir-grouping = "first";
      };
      symlink-arrow = "⇒";
    };
  };
}
