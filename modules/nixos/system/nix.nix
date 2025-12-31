# Nix daemon and flake settings
{ pkgs, lib, ... }:

{
  nix = {
    package = pkgs.nixVersions.latest;

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
      warn-dirty = false;

      # Build performance
      max-jobs = "auto";  # Use all available cores
      cores = 0;          # Use all cores per job

      # Binary caches - official and community (via Cachix)
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"  # Popular WM and related packages
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];

      # Fallback to building if cache unavailable
      fallback = true;

      # Build optimization
      keep-outputs = true;      # Keep build outputs for faster rebuilds
      keep-derivations = true;  # Keep derivations for nix-shell

      # Reduce build isolation for speed (safe for NixOS)
      sandbox = true;
      builders-use-substitutes = true;  # Let builders use binary cache
    };

    # Optimize during builds
    optimise = {
      automatic = true;
      dates = [ "daily" ];  # Run daily instead of only during GC
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
