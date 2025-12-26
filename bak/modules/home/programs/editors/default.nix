# Editor configurations - neovim, vscode, claude-code
{ config, pkgs, lib, ... }:

{
  imports = [
    ./neovim.nix
    ./vscode.nix
    ./claude-code.nix
  ];
}
