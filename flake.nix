{
  description = "NixOS configuration for toaster - gaming + pentesting workstation";

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
    vars = import ./vars.nix;

    # Allow unfree packages
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.${vars.hostname} = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; };

      modules = [
        # Allow unfree in nixos config
        { nixpkgs.config.allowUnfree = true; }

        # Disk layout
        disko.nixosModules.disko
        ./disko.nix

        # Core config
        ./configuration.nix

        # Impermanence (Phase 2 - uncomment when ready)
        impermanence.nixosModules.impermanence
        # ./modules/impermanence.nix

        # Secrets management (enable when ready)
        # sops-nix.nixosModules.sops

        # Home manager as NixOS module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.${vars.user.name} = import ./home/draxel.nix;
        }

        # Hardware-specific optimizations (uncomment if applicable)
        # nixos-hardware.nixosModules.common-cpu-amd
        # nixos-hardware.nixosModules.common-gpu-nvidia
        # nixos-hardware.nixosModules.common-pc-ssd
      ];
    };

    # Development shell with commands
    devShells.${system}.default = devshell.legacyPackages.${system}.mkShell {
      name = "Toaster Dev Shell";

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
          help = "Rebuild and switch (fast, 8 jobs, 2 cores/job for 9800X3D)";
          command = ''
            sudo nixos-rebuild switch --flake ".#${vars.hostname}" --no-reexec -j 8 --cores 2 "$@"
          '';
        }
        {
          name = "rebuild-boot";
          category = "nixos";
          help = "Rebuild for next boot (doesn't switch now)";
          command = ''
            sudo nixos-rebuild boot --flake ".#${vars.hostname}" --no-reexec -j 8 --cores 2 "$@"
          '';
        }
        {
          name = "rebuild-test";
          category = "nixos";
          help = "Test rebuild (doesn't add to boot menu)";
          command = ''
            sudo nixos-rebuild test --flake ".#${vars.hostname}" --no-reexec -j 8 --cores 2 "$@"
          '';
        }
        {
          name = "rebuild-dry";
          category = "nixos";
          help = "Dry run - show what would be built";
          command = ''
            nixos-rebuild dry-build --flake ".#${vars.hostname}" "$@"
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
            nixos-rebuild build --flake ".#${vars.hostname}" && \
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
      ];
    };
  };
}
