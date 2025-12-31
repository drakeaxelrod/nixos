# jless - JSON viewer with less-like interface
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    jless
  ];

  # Aliases for piping JSON
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    jl = "jless";
  };
}
