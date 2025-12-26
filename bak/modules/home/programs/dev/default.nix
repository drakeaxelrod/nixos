# Development tools - git, lazygit, etc.
{ config, pkgs, lib, ... }:

{
  imports = [
    ./git.nix
    ./lazygit.nix
    ./tools.nix
  ];
}
