# Desktop environment modules aggregator
{ ... }:

{
  imports = [
    ./gnome.nix
    ./steam.nix
    ./wayland.nix
  ];
}
