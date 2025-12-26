# Common desktop utilities
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    pavucontrol     # Audio control
  ];
}
