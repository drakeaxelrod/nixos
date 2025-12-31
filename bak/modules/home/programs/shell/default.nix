# Shell programs - zsh, starship, fzf, etc.
{ config, pkgs, lib, ... }:

{
  imports = [
    ./zsh.nix
    ./starship.nix
    ./fzf.nix
    ./zoxide.nix
    ./bat.nix
    ./lsd.nix
    ./direnv.nix
  ];
}
