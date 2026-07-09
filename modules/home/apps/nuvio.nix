# =============================================================================
# Nuvio - Modern Media Hub
# =============================================================================
#
# Modern media player with Stremio addon ecosystem support.
# Packaged as an AppImage — not yet in nixpkgs.
#
# Source: https://github.com/NuvioMedia/NuvioDesktop
#
# =============================================================================

{ pkgs, lib, ... }:

let
  version = "0.2.0";

  nuvio = pkgs.appimageTools.wrapType2 {
    pname = "nuvio";
    inherit version;
    # AppImage not yet on a stable release URL — reference the local file.
    # Requires --impure (already used in this flake).
    # Update this path if the file moves, or switch to fetchurl once the
    # correct upstream release URL is confirmed.
    src = builtins.path {
      path = /home/draxel/Downloads/Nuvio-0.2.0-x86_64.AppImage;
      name = "Nuvio-${version}-x86_64.AppImage";
    };
    meta = with lib; {
      description = "Modern media hub with Stremio addon ecosystem support";
      homepage = "https://github.com/NuvioMedia/NuvioDesktop";
      platforms = [ "x86_64-linux" ];
      mainProgram = "nuvio";
    };
  };
in

{
  home.packages = [ nuvio ];
}
