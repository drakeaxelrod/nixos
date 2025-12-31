# Helper function to create NixOS host configurations
#
# Usage in flake.nix:
#   mkHost = import ./lib/mkHost.nix { inherit inputs; };
#   nixosConfigurations.toaster = mkHost ./hosts/toaster;
#
{ inputs }:

hostPath:

let
  # Load host-specific variables
  hostVars = import (hostPath + "/vars.nix");

  # Merge with any user overrides
  vars = hostVars;

  system = vars.system or "x86_64-linux";

  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

in inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs vars;
  };

  modules = [
    # Allow unfree packages
    { nixpkgs.config.allowUnfree = true; }

    # Disko disk management
    inputs.disko.nixosModules.disko

    # Impermanence (optional)
    inputs.impermanence.nixosModules.impermanence

    # Secrets management
    inputs.sops-nix.nixosModules.sops

    # Home-manager as NixOS module
    inputs.home-manager.nixosModules.home-manager

    # Hardware optimizations from nixos-hardware
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    # Host-specific configuration (imports its own modules)
    (hostPath + "/default.nix")
  ];
}
