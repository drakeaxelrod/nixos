# Custom library functions for NixOS configuration
{ lib, inputs, ... }:

{
  # ===========================================================================
  # Libvirt XML generation helpers
  # ===========================================================================
  libvirt = import ./libvirt.nix { inherit lib; };

  # ===========================================================================
  # mkHost - Create a NixOS host configuration
  # ===========================================================================
  #
  # Usage:
  #   lib.mkHost {
  #     hostname = "toaster";
  #     users = with self.users; [ draxel ];
  #   }
  #
  mkHost = {
    hostname,
    system ? "x86_64-linux",
    users ? [],          # List of user module paths (e.g., ./users/draxel)
    extraModules ? [],
  }: inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    # Pass our extended lib (with libvirt, etc.) to all modules
    inherit lib;

    specialArgs = {
      inherit inputs lib;
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
      ../modules/virtualization
      ../modules/vfio
      ../modules/vms
      ../modules/desktop
      ../modules/impermanence

      # Host-specific configuration
      ../hosts/${hostname}

      # Home Manager (user configs come from user modules)
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit inputs; };
        };
      }

    ] ++ users ++ extraModules;
  };
}
