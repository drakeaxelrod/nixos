# NixOS configuration for toaster - gaming + pentesting workstation
#
# Hardware: AMD Ryzen 7 9800X3D, RTX 5070 Ti, 64GB DDR5, 2x 2TB NVMe RAID 1
# Features: VFIO GPU passthrough, Looking Glass, Docker, Tailscale
#
# Boot modes:
#   Default:  NVIDIA on host (CUDA, Docker GPU, gaming)
#   VFIO:     NVIDIA isolated for VM passthrough (Looking Glass)

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

  # Use latest kernel for best RDNA 3 iGPU support (9800X3D)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kernel parameters (both modes)
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "mem_encrypt=on"  # AMD SME - encrypts RAM
    # AMD GPU display options
    "amdgpu.dc=1"     # Enable Display Core (required for modern displays)
    "amdgpu.dcdebugmask=0x10"  # Helps with EDID issues
  ];

  # Kernel modules - Default mode (NVIDIA on host)
  # amdgpu: early KMS for AMD iGPU (host display)
  # vfio modules loaded but NOT binding GPU (no vfio-pci.ids set)
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" "kvmfr" "vfio_pci" "vfio" "vfio_iommu_type1" ];
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Firmware (AMD GPU, WiFi, etc.) - includes linux-firmware for AMD
  hardware.enableRedistributableFirmware = true;

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
  # Desktop Environment - GNOME on Wayland
  # ==========================================================================

  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Wayland environment
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";           # Electron apps use Wayland
    MOZ_ENABLE_WAYLAND = "1";        # Firefox Wayland
    QT_QPA_PLATFORM = "wayland";     # Qt apps use Wayland
    SDL_VIDEODRIVER = "wayland";     # SDL games use Wayland
    XDG_SESSION_TYPE = "wayland";
  };

  # XDG portal for proper Wayland app integration
  xdg.portal = {
    enable = true;
    wlr.enable = true;  # wlroots portal (screen sharing, etc.)
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  # ==========================================================================
  # Graphics - AMD iGPU (host display)
  # ==========================================================================

  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For 32-bit apps/games
  };

  # AMD GPU driver (early KMS)
  hardware.amdgpu.initrd.enable = true;

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

  programs.zsh.enable = true;

  users.users.${vars.user.name} = {
    isNormalUser = true;
    description = vars.user.description;
    shell = pkgs.${vars.user.shell};
    extraGroups = vars.user.groups;
    initialPassword = vars.user.initialPassword;
  };

  # ==========================================================================
  # NVIDIA Configuration (Default Mode - GPU on Host)
  # ==========================================================================
  # In default boot: NVIDIA driver loads, GPU available for CUDA/Docker/gaming
  # In VFIO boot: NVIDIA blacklisted, vfio-pci grabs GPU for VM passthrough

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;  # RTX 50 series uses open kernel modules
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  # Docker GPU access (default mode only)
  hardware.nvidia-container-toolkit.enable = true;

  # ==========================================================================
  # Virtualization
  # ==========================================================================

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;  # TPM emulation for Windows 11
    };
  };

  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
  };

  # ==========================================================================
  # Looking Glass & KVMFR (Low-latency VM display)
  # ==========================================================================

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
      local = {
        onCalendar = "hourly";
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "2d";
          snapshot_preserve = "24h 7d 4w";

          volume."/" = {
            subvolume."/home" = {
              snapshot_dir = "/.snapshots/home";
            };
            subvolume."/work" = {
              snapshot_dir = "/.snapshots/work";
              snapshot_preserve = "48h 14d 8w";
            };
          };
        };
      };

      system = {
        onCalendar = "weekly";
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "7d";
          snapshot_preserve = "4w";

          volume."/" = {
            subvolume."/@rootfs" = {
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

  services.openssh.enable = true;

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

    # Wayland utilities
    wl-clipboard       # Clipboard support (wl-copy, wl-paste)
    wl-clip-persist    # Keep clipboard after app closes
    wlr-randr          # Display configuration for wlroots
    wayland-utils      # wayland-info
    xdg-utils          # xdg-open, etc.

    # Hardware info
    pciutils
    usbutils
    lm_sensors
    nvtopPackages.full
    mesa-demos         # OpenGL info (glxinfo, eglinfo)
    vulkan-tools       # vulkaninfo

    # VM/Gaming
    looking-glass-client
    scream

    # Networking
    tailscale
    bridge-utils

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

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # ==========================================================================
  # VFIO Specialization (Boot-time GPU Passthrough Mode)
  # ==========================================================================
  #
  # Creates boot entry: "NixOS - VFIO"
  # Select this when you want GPU passthrough to Windows VM
  #
  # Find your GPU IDs after first boot:
  #   lspci -nn | grep -i nvidia
  # Then update vars.gpu.vfioIds and rebuild
  #
  # Changes from default:
  #   - vfio-pci.ids binds NVIDIA GPU early (before nvidia driver)
  #   - nvidia/nvidia_drm/etc blacklisted
  #   - GPU isolated and ready for VM passthrough

  specialisation."VFIO".configuration = {
    system.nixos.tags = [ "with-vfio" ];

    # Add vfio-pci.ids to bind GPU early
    boot.kernelParams = lib.mkForce [
      "amd_iommu=on"
      "iommu=pt"
      "mem_encrypt=on"
    ] ++ lib.optionals (vars.gpu.vfioIds != []) [
      "vfio-pci.ids=${lib.concatStringsSep "," vars.gpu.vfioIds}"
    ];

    # Load vfio-pci in initrd to grab GPU before nvidia
    boot.initrd.kernelModules = [ "amdgpu" "vfio_pci" "vfio" "vfio_iommu_type1" ];

    # Blacklist ALL nvidia modules
    boot.blacklistedKernelModules = [
      "nouveau"
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];

    # Don't try to load nvidia driver
    services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
  };

  # ==========================================================================
  # System State Version
  # ==========================================================================

  system.stateVersion = vars.stateVersion;
}
