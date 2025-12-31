# Java development tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    jdk21
  ];
}
