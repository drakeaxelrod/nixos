# fd - A fast and user-friendly alternative to find
{ config, pkgs, lib, ... }:

{
  programs.fd = {
    enable = true;

    # Default ignore patterns (respects .gitignore by default)
    ignores = [
      ".git/"
      "node_modules/"
      ".direnv/"
    ];

    # Hidden files are shown by default with -H flag
    # Follow symlinks with -L flag
  };

  # Optional aliases for convenience
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    # Find files (already ignores .gitignore)
    fdd = "fd --type d";  # Find directories only
    fdf = "fd --type f";  # Find files only
    fdh = "fd --hidden";  # Include hidden files
  };
}
