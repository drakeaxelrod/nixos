{
  description = "NixOS configuration - modular, VFIO-optimized";

  inputs = {
    # Core
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Hardware optimizations
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Disk management
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ephemeral root
    impermanence.url = "github:nix-community/impermanence";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Development shells
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Utilities
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    disko,
    impermanence,
    home-manager,
    sops-nix,
    devshell,
    flake-utils,
    ...
  }@inputs:
  let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # Helper to create host configurations
    mkHost = hostname: nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; };

      modules = [
        # Allow unfree packages
        { nixpkgs.config.allowUnfree = true; }

        # Disko disk management
        disko.nixosModules.disko

        # SOPS secrets management
        sops-nix.nixosModules.sops

        # Impermanence
        impermanence.nixosModules.impermanence

        # Core modules (always loaded)
        ./modules/core
        ./modules/hardware
        ./modules/networking
        ./modules/services
        ./modules/security

        # Host-specific configuration
        ./hosts/${hostname}

        # Home Manager as NixOS module
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users = import ./home;
          };
        }
      ];
    };
  in {
    # NixOS configurations
    nixosConfigurations = {
      toaster = mkHost "toaster";
      # Add more hosts here:
      # server = mkHost "server";
      # laptop = mkHost "laptop";
    };

    # Development shell with useful commands
    devShells.${system}.default = devshell.legacyPackages.${system}.mkShell {
      name = "nixos-config";

      packages = with pkgs; [
        nil           # Nix LSP
        nixpkgs-fmt   # Nix formatter
        sops          # Secrets management
        age           # Encryption
        nvd           # Nix version diff
      ];

      commands = [
        {
          name = "rebuild";
          category = "nixos";
          help = "Rebuild and switch to new configuration";
          command = ''
            sudo nixos-rebuild switch --flake ".#toaster" --no-reexec -j 8 --cores 2 "$@"
          '';
        }
        {
          name = "rebuild-boot";
          category = "nixos";
          help = "Rebuild for next boot";
          command = ''
            sudo nixos-rebuild boot --flake ".#toaster" --no-reexec -j 8 --cores 2 "$@"
          '';
        }
        {
          name = "rebuild-test";
          category = "nixos";
          help = "Test rebuild without adding to boot menu";
          command = ''
            sudo nixos-rebuild test --flake ".#toaster" --no-reexec -j 8 --cores 2 "$@"
          '';
        }
        {
          name = "rebuild-dry";
          category = "nixos";
          help = "Dry run - show what would be built";
          command = ''
            nixos-rebuild dry-build --flake ".#toaster" "$@"
          '';
        }
        {
          name = "update";
          category = "nixos";
          help = "Update flake inputs";
          command = ''
            nix flake update "$@"
          '';
        }
        {
          name = "diff";
          category = "nixos";
          help = "Show diff between current and new system";
          command = ''
            nixos-rebuild build --flake ".#toaster" && \
            nvd diff /run/current-system result
          '';
        }
        {
          name = "gc";
          category = "nixos";
          help = "Garbage collect old generations";
          command = ''
            sudo nix-collect-garbage -d && nix-collect-garbage -d
          '';
        }
        {
          name = "fmt";
          category = "dev";
          help = "Format all nix files";
          command = ''
            find . -name '*.nix' -exec nixpkgs-fmt {} +
          '';
        }
        {
          name = "check";
          category = "dev";
          help = "Check flake for errors";
          command = ''
            nix flake check "$@"
          '';
        }
        {
          name = "sops-edit";
          category = "secrets";
          help = "Edit secrets file";
          command = ''
            sops secrets/secrets.yaml
          '';
        }
        {
          name = "discover-hardware";
          category = "setup";
          help = "Show hardware info for configuration";
          command = ''
            echo "=== GPU PCI IDs (for vfio-pci.ids) ==="
            lspci -nn | grep -i nvidia || echo "No NVIDIA GPU found"
            echo ""
            echo "=== GPU PCI Addresses (for libvirt) ==="
            lspci -D | grep -i nvidia || echo "No NVIDIA GPU found"
            echo ""
            echo "=== Network Interfaces ==="
            ip -o link show | awk -F': ' '{print $2}' | grep -v lo
            echo ""
            echo "=== IOMMU Groups ==="
            for d in /sys/kernel/iommu_groups/*/devices/*; do
              n=$(basename $(dirname $(dirname $d)))
              echo "Group $n: $(lspci -nns $(basename $d) 2>/dev/null)"
            done 2>/dev/null | sort -V || echo "IOMMU not available"
          '';
        }
      ];
    };
  };
}
