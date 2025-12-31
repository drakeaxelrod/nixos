{
  description = "NixOS configuration - modular, VFIO-optimized";

  inputs = {
    # Core
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Flake framework
    flake-parts.url = "github:hercules-ci/flake-parts";

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
    
    # Browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        # IMPORTANT: we're using "libgbm" and is only available in unstable so ensure
        # to have it up-to-date or simply don't specify nixpkgs input
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    let
      # Extend nixpkgs.lib with custom functions
      lib = nixpkgs.lib.extend (final: prev:
        import ./lib { lib = final; inherit inputs; }
      );
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Supported systems
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # =========================================================================
      # Flake-level outputs (not per-system)
      # =========================================================================
      flake = rec {
        # Custom library functions
        inherit lib;

        # Host configurations - defined in hosts/default.nix
        # (hosts/default.nix imports users/default.nix internally)
        hosts = import ./hosts { inherit lib; };

        # NixOS configurations
        nixosConfigurations = hosts;
      };

      # =========================================================================
      # Per-system outputs
      # =========================================================================
      perSystem = { config, system, ... }:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        # Development shell
        devShells.default = inputs.devshell.legacyPackages.${system}.mkShell {
          name = "MyNixOS";

          packages = with pkgs; [
            nil           # Nix LSP
            nixpkgs-fmt   # Nix formatter
            sops          # Secrets management
            age           # Encryption
            nvd           # Nix version diff
          ];

          commands = [
            {
              name = "nx";
              category = "nixos";
              help = "NixOS operations: nx <action> [host]";
              command = ''
                action="''${1:-}"
                host="''${2:-toaster}"
                shift 2 2>/dev/null || shift 1 2>/dev/null || true

                case "$action" in
                  switch|boot|test)
                    sudo nixos-rebuild "$action" --flake ".#$host" -j 8 --cores 2 "$@"
                    ;;
                  dry)
                    nixos-rebuild dry-build --flake ".#$host" "$@"
                    ;;
                  build)
                    nixos-rebuild build --flake ".#$host" "$@"
                    ;;
                  update)
                    nix flake update "$@"
                    ;;
                  diff)
                    nixos-rebuild build --flake ".#$host" && nvd diff /run/current-system result
                    ;;
                  gc)
                    sudo nix-collect-garbage -d && nix-collect-garbage -d
                    ;;
                  fmt)
                    find . -name '*.nix' -exec nixpkgs-fmt {} +
                    ;;
                  check)
                    nix flake check "$@"
                    ;;
                  *)
                    echo "nx - NixOS flake operations"
                    echo ""
                    echo "Usage: nx <action> [host] [extra-args...]"
                    echo ""
                    echo "Actions:"
                    echo "  switch  - Switch to new configuration"
                    echo "  boot    - Rebuild for next boot"
                    echo "  test    - Test without adding to boot menu"
                    echo "  dry     - Dry run - show what would be built"
                    echo "  build   - Build without activating"
                    echo "  update  - Update flake inputs"
                    echo "  diff    - Show diff between current and new"
                    echo "  gc      - Garbage collect old generations"
                    echo "  fmt     - Format nix files"
                    echo "  check   - Check flake for errors"
                    echo ""
                    echo "Host defaults to 'toaster' if not specified."
                    [ -n "$action" ] && exit 1 || exit 0
                    ;;
                esac
              '';
            }
            {
              name = "sops-edit";
              category = "secrets";
              help = "Edit secrets file";
              command = "sops secrets/secrets.yaml";
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

        # Formatter
        formatter = pkgs.nixpkgs-fmt;

        # Apps
        apps.disko = {
          type = "app";
          program = "${inputs.disko.packages.${system}.disko}/bin/disko";
        };
      };
    };
}
