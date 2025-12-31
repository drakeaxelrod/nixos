# Desktop programs - GTK, Qt, GNOME, fonts, terminal
{ config, pkgs, lib, ... }:

{
  imports = [
    ./gtk.nix
    ./qt.nix
    ./gnome.nix
    ./terminal.nix
    ./fonts.nix
    ./packages.nix
  ];
}
