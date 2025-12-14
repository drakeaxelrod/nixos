# NixOS configuration for toaster - gaming + pentesting workstation
#
# Hardware: AMD Ryzen 7 9800X3D, RTX 5070 Ti, 64GB DDR5, 2x 2TB NVMe RAID 1
# Features: VFIO GPU passthrough, Looking Glass, Docker, Tailscale

{ config, pkgs, lib, ... }:

let
  vars = import ./vars.nix;
in
{
  # ==========================================================================
  # Boot Configuration
  # ==========================================================================

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.systemd-boot.configurationLimit = 10;

  # Kernel parameters
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "mem_encrypt=on"  # AMD SME - encrypts RAM
  ];

  # Kernel modules
  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];
  boot.kernelModules = [ "kvm-amd" "kvmfr" ];
  boot.blacklistedKernelModules = [ "nouveau" ];

  # ==========================================================================
  # Networking
  # ==========================================================================

  networking.hostName = vars.hostname;
  networking.networkmanager.enable = true;

  # Bridge network for VMs (direct LAN access, better than NAT)
  networking.bridges = lib.mkIf vars.network.bridge.enable {
    ${vars.network.bridge.name} = {
      interfaces = [ vars.network.bridge.interface ];
    };
  };

  # Bridge gets IP via DHCP
  networking.interfaces = lib.mkIf vars.network.bridge.enable {
    ${vars.network.bridge.name}.useDHCP = true;
    # Disable DHCP on physical interface (bridge handles it)
    ${vars.network.bridge.interface}.useDHCP = false;
  };

  # Firewall
  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = vars.network.trustedInterfaces;

  # Tailscale VPN
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";  # Exit node + subnet router

  # ==========================================================================
  # Localization
  # ==========================================================================

  time.timeZone = vars.timezone;
  i18n.defaultLocale = vars.locale;
  console.keyMap = vars.keymap;

  # ==========================================================================
  # Desktop Environment
  # ==========================================================================

  # GNOME + GDM with Wayland (uses AMD iGPU for host display)
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Graphics
  hardware.graphics.enable = true;

  # Remove GNOME bloat
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-music
    epiphany
    geary
  ];

  # ==========================================================================
  # User Account
  # ==========================================================================

  # Enable zsh system-wide (required for user shell)
  programs.zsh.enable = true;

  users.users.${vars.user.name} = {
    isNormalUser = true;
    description = vars.user.description;
    shell = pkgs.${vars.user.shell};
    extraGroups = vars.user.groups;
    initialPassword = vars.user.initialPassword;
  };

  # ==========================================================================
  # NVIDIA Configuration (Host Mode)
  # ==========================================================================

  # When booting default: GPU available on host for Ollama, Docker, CUDA
  # When booting VFIO specialization: GPU isolated for VM passthrough

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;  # RTX 50 series uses open kernel modules
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  hardware.nvidia-container-toolkit.enable = true;

  # ==========================================================================
  # Virtualization
  # ==========================================================================

  # Libvirt/QEMU/KVM
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      # ovmf removed - OVMF is now available by default in NixOS
      swtpm.enable = true;  # TPM emulation for Windows 11
    };
  };

  # Virt-manager GUI
  programs.virt-manager.enable = true;

  # SPICE USB redirection
  virtualisation.spiceUSBRedirection.enable = true;

  # Docker
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
  };

  # ==========================================================================
  # Looking Glass (Low-latency VM display)
  # ==========================================================================

  # KVMFR module for Looking Glass (better performance than IVSHMEM)
  boot.extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];

  # Shared memory for Looking Glass
  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 ${vars.user.name} libvirtd -"
  ];

  # udev rules for KVMFR and USB passthrough
  services.udev.extraRules = ''
    # KVMFR device permissions
    SUBSYSTEM=="kvmfr", OWNER="${vars.user.name}", GROUP="libvirtd", MODE="0660"

    # USB device passthrough permissions
    ${lib.concatMapStringsSep "\n" (vendor: ''SUBSYSTEM=="usb", ATTR{idVendor}=="${vendor}", MODE="0666"'') vars.usb.passthroughVendors}
  '';

  # ==========================================================================
  # Scream Audio (Low-latency VM audio)
  # ==========================================================================

  systemd.user.services.scream = {
    description = "Scream audio receiver";
    wantedBy = [ "graphical-session.target" ];
    after = [ "pipewire.service" ];
    serviceConfig = {
      # Use bridge if enabled, otherwise libvirt's NAT bridge
      ExecStart = "${pkgs.scream}/bin/scream -i ${if vars.network.bridge.enable then vars.network.bridge.name else "virbr0"} -o pipewire";
      Restart = "always";
      RestartSec = "5";
    };
  };

  # ==========================================================================
  # Btrfs Snapshots (btrbk)
  # ==========================================================================

  services.btrbk = {
    instances = {
      # Hourly snapshots for critical user data
      local = {
        onCalendar = "hourly";
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "2d";
          snapshot_preserve = "24h 7d 4w";

          volume."/" = {
            subvolume = {
              home = {
                snapshot_dir = "/.snapshots/home";
              };
              work = {
                snapshot_dir = "/.snapshots/work";
                snapshot_preserve = "48h 14d 8w";  # Longer for client work
              };
            };
          };
        };
      };

      # Weekly snapshots for root (reproducible via NixOS anyway)
      system = {
        onCalendar = "weekly";
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "7d";
          snapshot_preserve = "4w";

          volume."/" = {
            subvolume."" = {
              snapshot_dir = "/.snapshots/rootfs";
            };
          };
        };
      };
    };
  };

  # ==========================================================================
  # Services
  # ==========================================================================

  # SSH (for remote setup/recovery)
  services.openssh.enable = true;

  # Automatic Btrfs scrub (monthly data integrity check)
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # ==========================================================================
  # Packages
  # ==========================================================================

  environment.systemPackages = with pkgs; [
    # System utilities
    vim
    git
    htop
    btop
    wget
    curl
    tree
    ripgrep
    fd

    # Hardware info
    pciutils
    usbutils
    lm_sensors
    nvtopPackages.full

    # VM/Gaming
    looking-glass-client
    scream

    # Networking
    tailscale
    bridge-utils  # brctl for bridge debugging

    # Development
    gcc
    gnumake

    # GNOME extras
    gnome-extension-manager
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
  ];

  # ==========================================================================
  # Nix Configuration
  # ==========================================================================

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  # allowUnfree is set in flake.nix

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # ==========================================================================
  # VFIO Specialization (Boot-time GPU selection)
  # ==========================================================================

  # Creates second boot entry: "NixOS - VFIO"
  # Select this when you want GPU passthrough to VM
  #
  # After first boot, find your GPU IDs:
  #   lspci -nn | grep -i nvidia
  # Then update vars.gpu.vfioIds and rebuild

  specialisation."VFIO".configuration = {
    system.nixos.tags = [ "with-vfio" ];

    boot.kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "mem_encrypt=on"
    ] ++ lib.optionals (vars.gpu.vfioIds != []) [
      "vfio-pci.ids=${lib.concatStringsSep "," vars.gpu.vfioIds}"
    ];

    # When VFIO specialization is active, don't load nvidia driver
    boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  };

  # ==========================================================================
  # System State Version
  # ==========================================================================

  system.stateVersion = vars.stateVersion;
}
