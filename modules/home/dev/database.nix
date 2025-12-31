# Database client tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    postgresql
    sqlite
  ];
}
