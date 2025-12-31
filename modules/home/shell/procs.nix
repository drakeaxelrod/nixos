# procs - Modern ps replacement with colors and tree view
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    procs
  ];

  # Aliases
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    p = "procs";
    pt = "procs --tree";
    pw = "procs --watch";
  };
}
