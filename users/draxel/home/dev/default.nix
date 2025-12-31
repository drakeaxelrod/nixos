# Development tools and configurations
{ ... }:

{
  imports = [
    ./git.nix
    ./lazygit.nix
    ./tools.nix
  ];
}
