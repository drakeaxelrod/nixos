# API testing and HTTP tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    curl
    jq
    # yq provided by shell/jq.nix (yq-go)
  ];
}
