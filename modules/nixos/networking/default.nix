# Networking modules aggregator
{ ... }:

{
  imports = [
    ./base.nix
    ./bridge.nix
    ./firewall.nix
    ./tailscale.nix
    ./wireguard.nix
  ];
}
