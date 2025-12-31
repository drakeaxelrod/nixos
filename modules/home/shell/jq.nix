# jq - Command-line JSON processor
{ config, pkgs, lib, ... }:

{
  programs.jq = {
    enable = true;
  };

  # yq - YAML/XML/TOML processor (jq wrapper for multiple formats)
  home.packages = with pkgs; [
    yq-go  # yq written in Go (preferred over Python version)
  ];

  # Aliases
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    jqc = "jq -C";  # Colorized output
    jqr = "jq -r";  # Raw output (no quotes)
  };
}
