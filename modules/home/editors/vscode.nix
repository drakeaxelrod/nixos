# VSCode configuration
{ config, pkgs, lib, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

  # Wayland flags for VS Code / Electron apps
  # These enable native Wayland support but Electron prints warnings about them
  # The flags still work correctly despite the warnings
  xdg.configFile."code-flags.conf".text = ''
    --ozone-platform-hint=auto
    --enable-features=WaylandWindowDecorations
    --enable-wayland-ime
    --wayland-text-input-version=3
  '';
}
