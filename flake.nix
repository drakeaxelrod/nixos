{
  description = "NixOS configuration";

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

    # Plasma Manager
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Hyprland - dynamic tiling Wayland compositor
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixVim - Neovim configuration in Nix
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
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
          name = "nixdots";

          packages = with pkgs; [
            nil           # Nix LSP
            nixpkgs-fmt   # Nix formatter
            sops          # Secrets management
            age           # Encryption
            nvd           # Nix version diff
            jq            # JSON processor (required by nx script)

            # Shell tools for better dev experience
            starship      # Prompt
            bat           # Better cat
            lsd           # Better ls
            ripgrep       # Better grep
            fd            # Better find
            fzf           # Fuzzy finder
            zsh           # Include zsh for auto-launch
          ];

          # Auto-launch zsh on devshell entry
          bash = {
            extra = ''
              if [[ $SHLVL -eq 1 ]] && command -v zsh &> /dev/null; then
                exec zsh
              fi
            '';
          };

          commands = [
            {
              name = "nx";
              category = "nixos";
              help = "NixOS operations: nx <action> [host]";
              command = builtins.readFile ./scripts/nx.sh;
            }
            {
              name = "gacp";
              category = "git";
              help = "Git add, commit (AI), push: gacp [-m 'msg'] [-y]";
              command = builtins.readFile ./scripts/gacp.sh;
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
            {
              name = "find-desktop";
              category = "desktop";
              help = "Search for .desktop files: find-desktop <pattern>";
              command = ''
                pattern="''${1:-}"
                if [[ -z "$pattern" ]]; then
                  echo "Usage: find-desktop <pattern>"
                  echo "Searches for .desktop files matching pattern"
                  echo ""
                  echo "Example: find-desktop firefox"
                  exit 1
                fi

                # XDG Desktop Entry paths per freedesktop.org spec + NixOS paths
                search_paths=(
                  # User locations
                  "$HOME/.local/share/applications"
                  "$HOME/.local/share/flatpak/exports/share/applications"

                  # System locations (freedesktop.org)
                  "/usr/local/share/applications"
                  "/usr/share/applications"

                  # NixOS-specific locations
                  "/run/current-system/sw/share/applications"
                  "$HOME/.nix-profile/share/applications"
                  "/etc/profiles/per-user/$USER/share/applications"
                )

                # Add XDG_DATA_DIRS locations
                IFS=':' read -ra xdg_dirs <<< "''${XDG_DATA_DIRS:-}"
                for dir in "''${xdg_dirs[@]}"; do
                  search_paths+=("$dir/applications")
                done

                echo "Searching for: $pattern"
                echo "=========================================="

                found=0
                for path in "''${search_paths[@]}"; do
                  if [[ -d "$path" ]]; then
                    matches=$(find "$path" -maxdepth 1 -name "*.desktop" -iname "*$pattern*" 2>/dev/null)
                    if [[ -n "$matches" ]]; then
                      echo ""
                      echo "📁 $path"
                      echo "$matches" | while read -r file; do
                        name=$(basename "$file")
                        # Extract Name= from desktop file
                        display_name=$(grep -m1 "^Name=" "$file" 2>/dev/null | cut -d= -f2-)
                        echo "  → $name"
                        [[ -n "$display_name" ]] && echo "    Name: $display_name"
                      done
                      found=1
                    fi
                  fi
                done

                if [[ $found -eq 0 ]]; then
                  echo "No .desktop files found matching: $pattern"
                fi
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
