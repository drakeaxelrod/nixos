# Lua development tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    luajit      # LuaJIT - fast JIT compiler for Lua 5.1
    luarocks    # Lua package manager
    lua-language-server  # LSP for Lua
  ];
}
