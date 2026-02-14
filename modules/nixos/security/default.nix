# Security modules aggregator
{ ... }:

{
  imports = [
    ./base.nix
    ./fido.nix
    ./sops.nix
  ];
}
