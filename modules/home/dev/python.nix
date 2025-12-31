# Python development tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    python312
    python312Packages.pip
    python312Packages.virtualenv
    uv  # Fast Python package installer
  ];

  home.sessionVariables = {
    PYTHONUSERBASE = "${config.xdg.dataHome}/python";
    UV_CACHE_DIR = "${config.xdg.cacheHome}/uv";
  };

  home.sessionPath = [
    "${config.xdg.dataHome}/python/bin"
  ];
}
