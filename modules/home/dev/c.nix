# C/C++ development tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    gcc
    gnumake
    cmake
    ninja
  ];
}
