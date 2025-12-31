# Nix daemon and flake settings
{ pkgs, lib, ... }:

{
  nix = {
    package = pkgs.nixVersions.latest;

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
      # Helpful for debugging
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
