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

      # NixOS modules (system-level) following import-based pattern
      # Usage in hosts: imports = [ modules.nixos.desktop.gnome modules.nixos.system.locale ];
      modules.nixos = {
        # System configuration modules (boot, locale, nix, users)
        system = {
          boot = "${inputs.self}/modules/nixos/system/boot";  # Bootloader selection (aggregator)
          locale = "${inputs.self}/modules/nixos/system/locale.nix";
          nix = "${inputs.self}/modules/nixos/system/nix.nix";
          packages = "${inputs.self}/modules/nixos/system/packages.nix";
          users = "${inputs.self}/modules/nixos/system/users.nix";
        };
        # Desktop modules
        desktop = {
          # Display managers
          display = {
            gdm = "${inputs.self}/modules/nixos/desktop/display/gdm.nix";
            sddm = "${inputs.self}/modules/nixos/desktop/display/sddm.nix";
          };
          # Desktop managers (environments)
          managers = {
            gnome = "${inputs.self}/modules/nixos/desktop/managers/gnome.nix";
            plasma = "${inputs.self}/modules/nixos/desktop/managers/plasma.nix";
            hyprland = "${inputs.self}/modules/nixos/desktop/managers/hyprland.nix";
            # Gaming moved to separate section
          };
        };
        # Hardware modules
        hardware = {
          amd = "${inputs.self}/modules/nixos/hardware/amd.nix";
          audio = "${inputs.self}/modules/nixos/hardware/audio.nix";
          bluetooth = "${inputs.self}/modules/nixos/hardware/bluetooth.nix";
          nvidia = "${inputs.self}/modules/nixos/hardware/nvidia.nix";
          storage = "${inputs.self}/modules/nixos/hardware/storage.nix";
        };
        # Networking modules
        networking = {
          base = "${inputs.self}/modules/nixos/networking/base.nix";
          bridge = "${inputs.self}/modules/nixos/networking/bridge.nix";
          firewall = "${inputs.self}/modules/nixos/networking/firewall.nix";
          tailscale = "${inputs.self}/modules/nixos/networking/tailscale.nix";
        };
        # Service modules
        services = {
          btrbk = "${inputs.self}/modules/nixos/services/btrbk.nix";
          ollama = "${inputs.self}/modules/nixos/services/ollama.nix";
          openssh = "${inputs.self}/modules/nixos/services/openssh.nix";
          packages = "${inputs.self}/modules/nixos/services/packages.nix";
          printing = "${inputs.self}/modules/nixos/services/printing.nix";
          sunshine = "${inputs.self}/modules/nixos/services/sunshine.nix";
        };
        # Security modules
        security = {
          base = "${inputs.self}/modules/nixos/security/base.nix";
          sops = "${inputs.self}/modules/nixos/security/sops.nix";
        };
        # Virtualization modules
        virtualization = {
          docker = "${inputs.self}/modules/nixos/virtualization/docker.nix";
          libvirt = "${inputs.self}/modules/nixos/virtualization/libvirt.nix";
        };
        # VFIO modules - fully granular
        vfio = {
          passthrough = "${inputs.self}/modules/nixos/vfio/passthrough.nix";
          gpuPassthrough = "${inputs.self}/modules/nixos/vfio/default.nix";  # Main VFIO module with specializations
          lookingGlass = "${inputs.self}/modules/nixos/vfio/looking-glass.nix";
          scream = "${inputs.self}/modules/nixos/vfio/scream.nix";
        };
        # VM configuration
        vms = "${inputs.self}/modules/nixos/vms/default.nix";
        # Impermanence
        impermanence = "${inputs.self}/modules/nixos/impermanence/default.nix";
        # Gaming
        gaming = {
          steam = "${inputs.self}/modules/nixos/gaming/steam.nix";
          lutris = "${inputs.self}/modules/nixos/gaming/lutris.nix";
          heroic = "${inputs.self}/modules/nixos/gaming/heroic.nix";
        };
      };
    };

    modules = [
      # Nixpkgs configuration (unfree packages + overlays)
      {
        nixpkgs.config = {
          allowUnfree = true;

          # Allow specific insecure packages when needed
          # NOTE: Only add packages here if absolutely necessary
          # See: https://github.com/NixOS/nixpkgs/issues/437992
          permittedInsecurePackages = [
            # Stremio requires orphaned qtwebengine-5.15.19
            "qtwebengine-5.15.19"
          ];
        };
      }

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

      # NixOS modules (system-level)
      # System modules that provide essential options (always loaded)
      "${inputs.self}/modules/nixos/system"

      # All other modules are opt-in via imports in host configs
      # Usage: imports = [ modules.nixos.desktop.gnome modules.nixos.desktop.gdm ];
      # Hosts must explicitly import only the modules they need

      # Host-specific configuration
      "${inputs.self}/hosts/${hostname}"

      # Home Manager (user configs come from user modules)
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";  # Backup conflicting files with .backup extension

          extraSpecialArgs = {
            inherit inputs;
            # Shared home-manager modules following import-based pattern
            # Usage: imports = [ modules.home.shell.zsh modules.home.desktop.gnome ];
            modules.home = {
              # Desktop environment user configurations
              desktop = {
                gnome = "${inputs.self}/modules/home/desktop/gnome";
                plasma = "${inputs.self}/modules/home/desktop/plasma";
                hyprland = "${inputs.self}/modules/home/desktop/hyprland";
              };
              # Shell configurations
              shell = {
                bat = "${inputs.self}/modules/home/shell/bat.nix";
                btop = "${inputs.self}/modules/home/shell/btop.nix";
                delta = "${inputs.self}/modules/home/shell/delta.nix";
                direnv = "${inputs.self}/modules/home/shell/direnv.nix";
                dog = "${inputs.self}/modules/home/shell/dog.nix";
                fastfetch = "${inputs.self}/modules/home/shell/fastfetch.nix";
                fd = "${inputs.self}/modules/home/shell/fd.nix";
                fzf = "${inputs.self}/modules/home/shell/fzf.nix";
                gping = "${inputs.self}/modules/home/shell/gping.nix";
                grc = "${inputs.self}/modules/home/shell/grc.nix";
                jless = "${inputs.self}/modules/home/shell/jless.nix";
                jq = "${inputs.self}/modules/home/shell/jq.nix";
                lsd = "${inputs.self}/modules/home/shell/lsd.nix";
                procs = "${inputs.self}/modules/home/shell/procs.nix";
                ripgrep = "${inputs.self}/modules/home/shell/ripgrep.nix";
                starship = "${inputs.self}/modules/home/shell/starship.nix";
                xh = "${inputs.self}/modules/home/shell/xh.nix";
                zoxide = "${inputs.self}/modules/home/shell/zoxide.nix";
                zsh = "${inputs.self}/modules/home/shell/zsh.nix";
              };
              # Development tools
              dev = {
                git = "${inputs.self}/modules/home/dev/git.nix";
                lazygit = "${inputs.self}/modules/home/dev/lazygit.nix";
                # Language-specific tools
                rust = "${inputs.self}/modules/home/dev/rust.nix";
                go = "${inputs.self}/modules/home/dev/go.nix";
                nodejs = "${inputs.self}/modules/home/dev/nodejs.nix";
                python = "${inputs.self}/modules/home/dev/python.nix";
                java = "${inputs.self}/modules/home/dev/java.nix";
                c = "${inputs.self}/modules/home/dev/c.nix";
                lua = "${inputs.self}/modules/home/dev/lua.nix";
                nix = "${inputs.self}/modules/home/dev/nix.nix";
                # Utilities
                database = "${inputs.self}/modules/home/dev/database.nix";
                api = "${inputs.self}/modules/home/dev/api.nix";
                build = "${inputs.self}/modules/home/dev/build.nix";
              };
              # Editors
              editors = {
                claudeCode = "${inputs.self}/modules/home/editors/claude-code.nix";
                nixvim = "${inputs.self}/modules/home/editors/nixvim.nix";
                vscode = "${inputs.self}/modules/home/editors/vscode.nix";
              };
              # Applications
              apps = {
                moonlight = "${inputs.self}/modules/home/apps/moonlight.nix";
                steam = "${inputs.self}/modules/home/apps/steam.nix";
                stremio = "${inputs.self}/modules/home/apps/stremio.nix";
                zenBrowser = "${inputs.self}/modules/home/apps/zen-browser.nix";
              };
            };
          };
        };
      }

    ] ++ users ++ extraModules;
  };
}
