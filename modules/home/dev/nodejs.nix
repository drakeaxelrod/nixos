# Node.js development tools
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs_22
    pnpm
    yarn
  ];

  home.sessionVariables = {
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    NPM_CONFIG_PREFIX = "${config.xdg.dataHome}/npm";
    PNPM_HOME = "${config.xdg.dataHome}/pnpm";
    YARN_CACHE_FOLDER = "${config.xdg.cacheHome}/yarn";
  };

  home.sessionPath = [
    "${config.xdg.dataHome}/npm/bin"
    "${config.xdg.dataHome}/pnpm"
  ];
}
