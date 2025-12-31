# Hardware modules aggregator
{ ... }:

{
  imports = [
    ./amd.nix
    ./nvidia.nix
    ./audio.nix
    ./bluetooth.nix
    ./storage.nix
  ];
}
