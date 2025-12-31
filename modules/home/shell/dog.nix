# dog - Modern dig alternative with nice colorized output
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    dogdns
  ];

  # Aliases
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    dig = "dog";  # Replace dig with dog
  };
}
