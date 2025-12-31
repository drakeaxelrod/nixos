# Desktop environment modules aggregator
{ ... }:

{
  imports = [
    ./gdm.nix
    ./gnome.nix
    ./plasma.nix
    ./sddm.nix
    ./steam.nix
    ./wayland.nix
  ];
}
