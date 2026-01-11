# Flatpak support with proper desktop integration
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.services.flatpak;
in
{
  options.modules.services.flatpak = {
    enable = lib.mkEnableOption "Flatpak support with desktop integration";

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "com.stremio.Stremio" "com.spotify.Client" ];
      description = "List of Flatpak packages to install declaratively";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable Flatpak service
    services.flatpak.enable = true;

    # XDG Portal for Flatpak apps to access host resources
    xdg.portal = {
      enable = true;
      # Portal backends are usually set by desktop environment
      # extraPortals with xdg-desktop-portal-kde/gtk is handled by plasma/gnome modules
    };

    # Add Flatpak directories to XDG_DATA_DIRS so apps appear in launchers
    environment.sessionVariables = {
      XDG_DATA_DIRS = [
        "/var/lib/flatpak/exports/share"
        "$HOME/.local/share/flatpak/exports/share"
      ];
    };

    # Ensure the font cache is available to Flatpak apps
    fonts.fontDir.enable = true;

    # Activation script to:
    # 1. Add Flathub repository if not present
    # 2. Install declared packages
    system.activationScripts.flatpak = lib.mkIf (cfg.packages != [ ]) ''
      # Add Flathub if not present
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

      # Install declared packages
      ${lib.concatMapStringsSep "\n" (pkg: ''
        if ! ${pkgs.flatpak}/bin/flatpak info ${pkg} &>/dev/null; then
          echo "Installing Flatpak: ${pkg}"
          ${pkgs.flatpak}/bin/flatpak install -y flathub ${pkg} || true
        fi
      '') cfg.packages}
    '';
  };
}
