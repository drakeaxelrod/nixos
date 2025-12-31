{ config, pkgs, inputs, ... }:

{
  imports = [
    ./fonts.nix
    ./gnome.nix
    ./gtk.nix
    ./qt.nix
    #./gnome-terminal.nix
  ];
}