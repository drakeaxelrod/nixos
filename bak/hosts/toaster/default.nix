# NixOS configuration for toaster - gaming + pentesting workstation
#
# Hardware: AMD Ryzen 7 9800X3D, RTX 5070 Ti, 64GB DDR5, 2x 2TB NVMe RAID 1
# Features: VFIO GPU passthrough, Looking Glass, Docker, Tailscale

{ config, pkgs, lib, vars, inputs, ... }:

{
  imports = [
    # Disk layout (DO NOT MODIFY - current machine disk config)
    ./disko.nix

    # Core modules (always imported)
    ../../modules/nixos/core

    # Feature modules
    ../../modules/nixos/features/desktop/gnome.nix
    ../../modules/nixos/features/desktop/steam.nix
    ../../modules/nixos/features/hardware/audio.nix
    ../../modules/nixos/features/hardware/bluetooth.nix
    ../../modules/nixos/features/hardware/amd-gpu.nix
    ../../modules/nixos/features/hardware/zsa-keyboard.nix
    ../../modules/nixos/features/services/ssh.nix
    ../../modules/nixos/features/services/btrbk.nix
    ../../modules/nixos/features/virtualization/docker.nix
    ../../modules/nixos/features/virtualization/vfio.nix
    ../../modules/nixos/features/networking
    ../../modules/nixos/features/networking/tailscale.nix
    #../../modules/nixos/features/networking/bridge.nix

    # Users on this machine
    ../../users/draxel
  ];

  # ==========================================================================
  # Host Identity
  # ==========================================================================

  networking.hostName = vars.hostname;

  # ==========================================================================
  # Boot Configuration (host-specific)
  # ==========================================================================

  # EFI mount point specific to this host's disko layout
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Use 6.12 LTS kernel (NVIDIA driver compatible)
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Host-specific kernel parameters (appended to core params)
  boot.kernelParams = [
    "mem_encrypt=on"  # AMD memory encryption
  ];

  # Memory tuning for VM performance and stability
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;              # Prefer RAM over swap (but use zram when needed)
    "vm.vfs_cache_pressure" = 50;      # Keep directory/inode caches longer
    "vm.dirty_ratio" = 10;             # Start writeback at 10% dirty memory
    "vm.dirty_background_ratio" = 5;   # Background writeback at 5%
    "vm.panic_on_oom" = 0;             # Don't kernel panic on OOM
    "vm.overcommit_memory" = 0;        # Heuristic overcommit (default, safe)
    "kernel.sched_autogroup_enabled" = 0;  # Better for VM workloads
  };

  # ==========================================================================
  # ZRAM Swap (Compressed RAM)
  # ==========================================================================
  # With 64GB RAM minus 16GB hugepages, memory pressure can occur.
  # ZRAM provides compressed swap in RAM - much faster than disk swap.
  # This helps prevent OOM kills during memory spikes.

  zramSwap = {
    enable = true;
    algorithm = "zstd";      # Best compression ratio
    memoryPercent = 25;      # 25% of RAM = ~16GB compressed swap
  };

  system.nixos.label = "VFIO";

  # ==========================================================================
  # Security (host-specific extras)
  # ==========================================================================

  # Allow nixos-rebuild without password for primary user
  security.sudo.extraRules = [{
    users = [ vars.primaryUser ];
    commands = [
      { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
    ];
  }];

  sops = {
    defaultSopsFile = ../../secrets/secrets.yml;
    age.keyFile = "/home/${vars.primaryUser}/.config/sops/age/keys.txt";
    secrets = { };
  };

  # ==========================================================================
  # Home Manager
  # ==========================================================================

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs vars; };
  };

  # ==========================================================================
  # Packages
  # ==========================================================================

  environment.localBinInPath = true;

  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    wget
    curl
    tree
    ripgrep
    fd

    # Security
    sops
    age

    # Networking
    tailscale
    bridge-utils
    ethtool

    # Development
    gcc
    gnumake

    # Appearance
    papirus-icon-theme
    nerd-fonts.lilex
    font-awesome
    inter

    # Applications
    remmina
    ktailctl
    qbittorrent
    fastfetch
    proton-pass

    # nixos-sync script
    (pkgs.writeShellScriptBin "nixos-sync" ''
      set -e
      SSH_KEY="/home/${vars.primaryUser}/.ssh/sops_ed25519"
      PROJECTS_DIR="/home/${vars.primaryUser}/Projects/nixos"
      NIXOS_DIR="/etc/nixos"

      cd "$PROJECTS_DIR"
      git add -A
      git commit -m "''${1:-update}" || true
      GIT_SSH_COMMAND="ssh -i $SSH_KEY" git push
      echo "Pushed from $PROJECTS_DIR"

      cd "$NIXOS_DIR"
      sudo GIT_SSH_COMMAND="ssh -i $SSH_KEY" git pull
      echo "Pulled to $NIXOS_DIR"

      echo "Rebuilding NixOS..."
      sudo nixos-rebuild switch --flake "$NIXOS_DIR#${vars.hostname}" --no-reexec -j 8 --cores 2
      echo "Done!"
    '')
  ];

  # ==========================================================================
  # System State Version
  # ==========================================================================

  system.stateVersion = vars.stateVersion;
}
