# System services modules aggregator
{ ... }:

{
  imports = [
    ./openssh.nix
    ./btrbk.nix
    ./printing.nix
    ./packages.nix
    ./ollama.nix
    ./flatpak.nix
  ];
}
