# Virtualization modules aggregator
{ ... }:

{
  imports = [
    ./libvirt.nix
    ./docker.nix
  ];
}
