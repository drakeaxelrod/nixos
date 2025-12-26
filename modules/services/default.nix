# System services modules aggregator
{ ... }:

{
  imports = [
    ./openssh.nix
    ./btrbk.nix
    ./packages.nix
  ];
}
