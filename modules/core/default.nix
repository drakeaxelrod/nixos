# Core system modules - essential for any NixOS system
{ ... }:

{
  imports = [
    ./boot.nix
    ./nix.nix
    ./locale.nix
    ./users.nix
  ];
}
