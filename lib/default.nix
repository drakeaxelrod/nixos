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
  #     stateVersion = "25.11";  # Optional, defaults to "25.11"
  #     users = with self.users; [ draxel ];
  #   }
  #
  # Provides meta to all modules:
  #   meta.hostname      -> "toaster"
  #   meta.stateVersion  -> "25.11"
  #   meta.users         -> ["draxel"]  # List of username strings
  #
  mkHost = {
    hostname,
    system ? "x86_64-linux",
    stateVersion ? "25.11",  # NixOS state version
    users ? [],              # List of user module paths (e.g., ./users/draxel)
    extraModules ? [],
  }:
  let
    # Extract usernames from user module paths
    # e.g., ./users/draxel -> "draxel"
    usernames = map (userPath:
      let
        pathStr = toString userPath;
        parts = lib.splitString "/" pathStr;
      in
        lib.last parts
    ) users;
  in
  inputs.nixpkgs.lib.nixosSystem {
    inherit system;

    # Pass our extended lib (with libvirt, etc.) to all modules
    inherit lib;

    specialArgs = {
      inherit inputs lib;
      inherit (inputs) self;

      # Host metadata available to all modules via meta argument
      meta = {
        inherit hostname stateVersion;
        users = usernames;  # List of username strings: ["draxel"]
      };
    };

    modules = [
      # Allow unfree packages
      { nixpkgs.config.allowUnfree = true; }

      # Set hostname and stateVersion from mkHost arguments
      {
        networking.hostName = hostname;
        system.stateVersion = stateVersion;
      }

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
