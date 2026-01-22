# Nix development tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nixpkgs-fmt
    nil  # Nix LSP
    nixfmt-rfc-style # Nix formatter with RFC style
  ];
}
