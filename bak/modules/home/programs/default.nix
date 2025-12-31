# All home-manager programs
{ config, pkgs, lib, ... }:

{
  imports = [
    ./shell
    ./dev
    ./editors
    ./desktop
  ];
}
