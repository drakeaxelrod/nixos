# Lua development tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    lua
    luajit
  ];
}
