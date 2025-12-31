# gping - Ping with a graph
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    gping
  ];

  # No aliases needed - gping is intuitive as-is
}
