# Core home-manager modules - always imported
{ config, pkgs, lib, ... }:

{
  imports = [
    ./xdg.nix
    ./environment.nix
  ];

  # Allow home-manager to manage itself
  programs.home-manager.enable = true;
}
