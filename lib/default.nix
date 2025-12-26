# Custom library functions for NixOS configuration
{ lib, inputs, ... }:

{
  # Helper to create a NixOS host configuration
  mkHost = {
    hostname,
    system ? "x86_64-linux",
    extraModules ? [],
  }: inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    specialArgs = {
      inherit inputs;
      inherit (inputs) self;
    };

    modules = [
      # Allow unfree packages
      { nixpkgs.config.allowUnfree = true; }

      # Disko disk management
      inputs.disko.nixosModules.disko

      # SOPS secrets management
      inputs.sops-nix.nixosModules.sops

      # Impermanence
      inputs.impermanence.nixosModules.impermanence

      # Core modules (always loaded)
      ../modules/core
      ../modules/hardware
      ../modules/networking
      ../modules/services
      ../modules/security

      # Host-specific configuration
      ../hosts/${hostname}

      # Home Manager as NixOS module
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
          users = import ../home;
        };
      }
    ] ++ extraModules;
  };
}
