# Go development tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    go
    gopls
    delve
  ];

  home.sessionVariables = {
    GOPATH = "${config.xdg.dataHome}/go";
    GOMODCACHE = "${config.xdg.cacheHome}/go/pkg/mod";
  };

  home.sessionPath = [
    "${config.xdg.dataHome}/go/bin"
  ];
}
