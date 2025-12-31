{
  description = "NixOS configurations - multi-machine, multi-user";

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
    # ==========================================================================
    # Helper function to create a host configuration
    # ==========================================================================
    mkHost = hostPath: let
      hostVars = import (hostPath + "/vars.nix");
      system = hostVars.system or "x86_64-linux";
      # Check for hardware features
      hasNvidia = hostVars.features.nvidia or false;
      hasAmd = hostVars.features.amdCpu or true;  # Default to AMD
    in nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs;
        vars = hostVars;
      };

      modules = [
        # Allow unfree packages
        { nixpkgs.config.allowUnfree = true; }

        # Disko disk management
        disko.nixosModules.disko

        # Impermanence (optional per-host)
        impermanence.nixosModules.impermanence

        # Secrets management
        sops-nix.nixosModules.sops

        # Home-manager as NixOS module
        home-manager.nixosModules.home-manager

        # Hardware optimizations (conditional)
        nixos-hardware.nixosModules.common-pc-ssd
      ]
      ++ nixpkgs.lib.optional hasAmd nixos-hardware.nixosModules.common-cpu-amd
      ++ nixpkgs.lib.optional hasNvidia nixos-hardware.nixosModules.common-gpu-nvidia
      ++ [
        # Host-specific configuration
        (hostPath + "/default.nix")
      ];
    };

    # ==========================================================================
    # For backwards compatibility and devshell
    # ==========================================================================
    system = "x86_64-linux";
    legacyVars = import ./vars.nix;

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

  in {
    # ==========================================================================
    # NixOS Configurations
    # ==========================================================================

    nixosConfigurations = {
      # Gaming + pentesting workstation
      toaster = mkHost ./hosts/toaster;

      # Dedicated pentesting machine
      honeypot = mkHost ./hosts/honeypot;

      # Barebones developer machine
      poptart = mkHost ./hosts/poptart;
    };

    # ==========================================================================
    # Development Shell
    # ==========================================================================

    devShells.${system}.default = devshell.legacyPackages.${system}.mkShell {
      name = "NixOS Dev Shell";

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
          help = "Rebuild and switch (fast, 8 jobs, 2 cores/job)";
          command = ''
            HOST="''${1:-toaster}"
            shift 2>/dev/null || true
            sudo nixos-rebuild switch --flake ".#$HOST" --no-reexec -j 8 --cores 2 "$@"
          '';
        }
        {
          name = "rebuild-boot";
          category = "nixos";
          help = "Rebuild for next boot (doesn't switch now)";
          command = ''
            HOST="''${1:-toaster}"
            shift 2>/dev/null || true
            sudo nixos-rebuild boot --flake ".#$HOST" --no-reexec -j 8 --cores 2 "$@"
          '';
        }
        {
          name = "rebuild-test";
          category = "nixos";
          help = "Test rebuild (doesn't add to boot menu)";
          command = ''
            HOST="''${1:-toaster}"
            shift 2>/dev/null || true
            sudo nixos-rebuild test --flake ".#$HOST" --no-reexec -j 8 --cores 2 "$@"
          '';
        }
        {
          name = "rebuild-dry";
          category = "nixos";
          help = "Dry run - show what would be built";
          command = ''
            HOST="''${1:-toaster}"
            shift 2>/dev/null || true
            nixos-rebuild dry-build --flake ".#$HOST" "$@"
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
          name = "git-pull";
          category = "git";
          help = "Pull with correct ssh key";
          command = ''
            sudo GIT_SSH_COMMAND='ssh -i /home/draxel/.ssh/sops_ed25519' git pull
          '';
        }
        {
          name = "diff";
          category = "nixos";
          help = "Show diff between current and new system";
          command = ''
            HOST="''${1:-toaster}"
            nixos-rebuild build --flake ".#$HOST" && \
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
            SOPS_AGE_KEY_FILE=/home/draxel/.config/sops/age/keys.txt sops /home/draxel/Projects/nixos/secrets/secrets.yaml
          '';
        }
      ];
    };
  };
}
