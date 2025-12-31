# xh - Fast and friendly HTTP client (HTTPie alternative in Rust)
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    xh
  ];

  # Aliases
  programs.zsh.shellAliases = lib.mkIf config.programs.zsh.enable {
    # xh is used directly, but add some common shortcuts
    xhg = "xh GET";
    xhp = "xh POST";
    xhput = "xh PUT";
    xhd = "xh DELETE";
  };
}
