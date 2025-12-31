# Build tools and task runners
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    just  # Command runner
    direnv
  ];
}
