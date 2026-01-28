# Security modules aggregator
{ ... }:

{
  imports = [
    ./base.nix
    ./sops.nix
    ./yubikey.nix
  ];
}
