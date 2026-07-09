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
    src = pkgs.fetchurl {
      url = "https://github.com/NuvioMedia/NuvioDesktop/releases/download/v${version}/Nuvio-${version}-x86_64.AppImage";
      hash = "sha256-vpgVTrgYRmCJOVbw5zQkuw5Wsg0PCA+ZGP3ZauXK4KU=";
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
