# Nix development tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nixpkgs-fmt
    nil  # Nix LSP
    nixfmt # Nix formatter (RFC style is now the default)
  ];
}
