# ripgrep - Extremely fast grep alternative that respects .gitignore
{ config, pkgs, lib, ... }:

{
  programs.ripgrep = {
    enable = true;

    arguments = [
      # Search hidden files/directories by default
      # "--hidden"

      # Follow symbolic links
      # "--follow"

      # Smart case: case-insensitive if pattern is all lowercase
      "--smart-case"

      # Show column numbers
      "--column"

      # Add custom type definitions
      "--type-add=nix:*.nix"
      "--type-add=org:*.org"
    ];
  };

  # Aliases
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    rgh = "rg --hidden";  # Search including hidden files
    rgf = "rg --files";   # List files that would be searched
  };
}
