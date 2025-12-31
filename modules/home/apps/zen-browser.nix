# Zen Browser - Modern Firefox-based browser with vertical tabs
{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  programs.zen-browser.enable = true;
}
