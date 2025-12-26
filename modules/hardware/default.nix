# Hardware modules aggregator
{ ... }:

{
  imports = [
    ./amd-cpu.nix
    ./amd-gpu.nix
    ./storage.nix
  ];
}
