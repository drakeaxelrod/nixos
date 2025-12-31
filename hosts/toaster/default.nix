# Toaster - Gaming + Pentesting Workstation
#
# Hardware: AMD Ryzen 7 7800X3D, NVIDIA RTX 5070 Ti, 64GB DDR5, 2x 2TB NVMe
# Features: VFIO GPU passthrough, Looking Glass, Impermanence
#
# Boot Menu (Limine):
#   - NixOS           → Host GPU mode (NVIDIA on host for gaming/CUDA)
#   - NixOS [vfio]    → VFIO mode (GPU isolated for Windows VM)
#
{ config, lib, pkgs, inputs, meta, modules, ... }:

let
  # Helper to get specific users from meta.users
  # Usage: users.draxel or users.all
  users = lib.genAttrs meta.users (name: name) // {
    all = meta.users;
  };
in

{
  imports = [
    ./disko.nix

    # Import-based pattern: explicitly import only needed modules

    # System packages (essential CLI tools available before home-manager)
    modules.nixos.system.packages

    # Desktop environment
    modules.nixos.desktop.display.gdm
    modules.nixos.desktop.managers.gnome

    # Applications
    modules.nixos.apps.steam

    # Hardware
    modules.nixos.hardware.amd
    modules.nixos.hardware.nvidia
    modules.nixos.hardware.audio
    modules.nixos.hardware.bluetooth

    # Networking
    modules.nixos.networking.tailscale

    # Services
    modules.nixos.services.openssh
    modules.nixos.services.btrbk

    # Virtualization
    modules.nixos.virtualization.libvirt
    modules.nixos.virtualization.docker

    # VFIO - granular imports
    modules.nixos.vfio.dualBoot      # Provides dualBoot option + auto-imports core
    modules.nixos.vfio.lookingGlass
    modules.nixos.vfio.scream

    # VMs
    modules.nixos.vms

    # Security
    modules.nixos.security.sops
  ];

  # ==========================================================================
  # System Identity
  # ==========================================================================
  # Derived from mkHost - no need to set here
  # networking.hostName = meta.hostname;      # "toaster"
  # system.stateVersion = meta.stateVersion;  # "25.11"

  # ==========================================================================
  # Bootloader - Limine for clean boot menu
  # ==========================================================================

  modules.system.boot = {
    loader = "limine";     # Modern, stylish bootloader
    maxGenerations = 10;    # Keep boot menu clean
    timeout = 5;           # 5 second timeout

    # Plymouth for graphical LUKS password prompt
    plymouth = {
      enable = true;
      theme = "breeze";      # KDE Breeze theme (modern and clean)
      silentBoot = true;     # Hide kernel messages for cleaner experience
    };
  };

  # ==========================================================================
  # Hardware Features
  # ==========================================================================

  # AMD CPU and iGPU (Radeon 780M)
  modules.hardware.amd.enable = true;

  # NVIDIA RTX 5070 Ti (discrete GPU)
  modules.hardware.nvidia = {
    enable = true;
    enableWayland = true;
    enableSuspendSupport = true;
    powerManagement.enable = true;

    # PRIME configuration for hybrid graphics (AMD iGPU + NVIDIA dGPU)
    prime = {
      enable = true;
      mode = "offload";  # On-demand NVIDIA rendering
      amdBusId = "PCI:13:0:0";    # AMD 780M iGPU (0d:00.0)
      nvidiaBusId = "PCI:1:0:0";  # NVIDIA RTX 5070 Ti (01:00.0)
    };
  };

  # Audio
  modules.hardware.audio.enable = true;

  # Bluetooth
  modules.hardware.bluetooth.enable = true;

  # ==========================================================================
  # GPU Mode (Dual-Boot)
  # ==========================================================================
  # Creates boot entries for switching GPU modes:
  #   - "NixOS - host": GPU available to host (NVIDIA drivers loaded)
  #   - "NixOS - vfio": GPU isolated for VM passthrough
  #
  # PCI IDs are auto-derived from virtualisation.vms GPU settings.

  modules.vfio.dualBoot = {
    enable = true;
    defaultMode = "host";  # "host" or "vfio"
  };
  #
  # # Looking Glass & Scream (active in VFIO mode)
  modules.vfio.lookingGlass = {
    enable = true;
    users = [ users.draxel ];  # Derived from meta.users
  };
  modules.vfio.scream.enable = true;

  # ==========================================================================
  # Virtualization
  # ==========================================================================

  modules.virtualization.libvirt = {
    enable = true;
    users = [ users.draxel ];  # Auto-added to libvirtd group
  };

  modules.virtualization.docker = {
    enable = true;
    users = [ users.draxel ];  # Auto-added to docker group
  };

  # ==========================================================================
  # Desktop Environment
  # ==========================================================================
  # Desktop modules are now imported above (import-based pattern)
  # Configuration is done here through options

  # Enable GNOME desktop
  modules.desktop.gnome.enable = true;

  # Enable GDM with Wayland
  modules.desktop.gdm = {
    enable = true;
    wayland = true;
  };

  # Enable Steam
  modules.desktop.steam.enable = true;

  # ==========================================================================
  # Networking
  # ==========================================================================

  # modules.networking.bridge = {
  #   enable = true;
  #   name = "br0";
  #   interface = "eth0";  # PLACEHOLDER - Update with: ip link
  # };

  modules.networking.tailscale.enable = true;

  # ==========================================================================
  # Services
  # ==========================================================================

  modules.services.openssh.enable = true;
  modules.services.btrbk.enable = true;

  # ==========================================================================
  # Impermanence (Ephemeral Root)
  # ==========================================================================

  # Disabled by default - enable after system is stable and @rootfs-blank snapshot exists
  # To enable:
  #   1. Boot system normally and ensure everything works
  #   2. Create blank root snapshot:
  #      sudo mount -o subvol=/ /dev/mapper/cryptroot1 /mnt
  #      sudo btrfs subvolume snapshot -r /mnt/@rootfs /mnt/@rootfs-blank
  #      sudo umount /mnt
  #   3. Set modules.impermanence.enable = true below
  #   4. Rebuild: nx switch
  # modules.impermanence.enable = true;

  # ==========================================================================
  # SOPS Secrets
  # ==========================================================================

  # Disabled by default - enable after setting up age keys
  modules.security.sops.enable = true;

  # ==========================================================================
  # Declarative Virtual Machines
  # ==========================================================================

  virtualisation.vms.win11 = {
    title = "Windows 11 Gaming";
    description = "Windows 11 VM with GPU passthrough for gaming";

    # Memory
    memory = {
      amount = 16384;  # 16GB
      unit = "MiB";
      hugepages = {
        enable = true;
        size = 1;      # 1GB hugepages
        count = 16;    # 16 hugepages
      };
    };

    # vCPUs
    vcpu = {
      count = 12;
      placement = "static";
    };

    # CPU
    cpu = {
      mode = "host-passthrough";
      topology = {
        sockets = 1;
        dies = 1;
        cores = 6;
        threads = 2;
      };
      # Hide hypervisor CPUID bits and expose cache topology
      feature = [
        { policy = "disable"; name = "hypervisor"; }  # Hide hypervisor presence from CPUID
        { policy = "require"; name = "topoext"; }     # Expose AMD topology extensions
        { policy = "require"; name = "invtsc"; }      # Invariant TSC for stable timekeeping
      ];
    };

    # CPU Pinning
    cputune = {
      vcpupin = [
        { vcpu = 0; cpuset = "4"; }
        { vcpu = 1; cpuset = "5"; }
        { vcpu = 2; cpuset = "6"; }
        { vcpu = 3; cpuset = "7"; }
        { vcpu = 4; cpuset = "8"; }
        { vcpu = 5; cpuset = "9"; }
        { vcpu = 6; cpuset = "10"; }
        { vcpu = 7; cpuset = "11"; }
        { vcpu = 8; cpuset = "12"; }
        { vcpu = 9; cpuset = "13"; }
        { vcpu = 10; cpuset = "14"; }
        { vcpu = 11; cpuset = "15"; }
      ];
      emulatorpin = {
        cpuset = "0-3";
      };
    };

    # OS
    os = {
      type = "hvm";
      arch = "x86_64";
      machine = "pc-q35-8.2";
      firmware = "efi";
      loader = {
        readonly = true;
        type = "pflash";
        secure = true;
        path = "/run/libvirt/nix-ovmf/OVMF_CODE.secboot.fd";
      };
      nvram = {
        template = "/run/libvirt/nix-ovmf/OVMF_VARS.secboot.fd";
        path = "/var/lib/libvirt/qemu/nvram/win11_VARS.fd";
      };
    };

    # Features
    features = {
      acpi = true;
      apic = true;
      hyperv = {
        relaxed = { state = "on"; };
        vapic = { state = "on"; };
        spinlocks = { state = "on"; retries = 8191; };
        vpindex = { state = "on"; };
        runtime = { state = "on"; };
        synic = { state = "on"; };
        stimer = { state = "on"; };
        stimer_direct = { state = "on"; };  # Direct mode for stimer (separate key)
        reset = { state = "on"; };
        vendor_id = { state = "on"; value = "GenuineIntel"; };  # Spoof as Intel
        frequencies = { state = "on"; };
        reenlightenment = { state = "on"; };
        tlbflush = { state = "on"; };
        ipi = { state = "on"; };
        evmcs = { state = "off"; };  # AMD host, disable enlightened VMCS
      };
      kvm = {
        hidden = { state = "on"; };  # Hide KVM hypervisor signature
      };
      vmport = { state = "off"; };  # Disable VMware port (VM detection vector)
      ioapic = { driver = "kvm"; };  # Use KVM IOAPIC for better performance
    };

    # Clock
    clock = {
      offset = "localtime";
      timers = {
        rtc = { tickpolicy = "catchup"; };
        pit = { tickpolicy = "delay"; };
        hpet = { present = false; };
        hypervclock = { present = true; };
      };
    };

    # Devices
    devices = {
      # Disks
      disks = [
        {
          type = "file";
          device = "disk";
          driver = {
            name = "qemu";
            type = "qcow2";
            cache = "writeback";
            io = "threads";
            discard = "unmap";
          };
          source.file = /var/lib/libvirt/images/win11.qcow2;
          size = "80G";  # Auto-create 80GB qcow2 if it doesn't exist
          target = {
            dev = "vda";
            bus = "virtio";
          };
          boot.order = 1;
        }
        # Uncomment for installation:  virtio-win-0.1.285.iso   Win11_25H2_English_x64.iso

        {
          type = "file";
          device = "cdrom";
          driver = {
            name = "qemu";
            type = "raw";
          };
          source.file = /var/lib/libvirt/boot/Win11_25H2_English_x64.iso;
          target = {
            dev = "sda";
            bus = "sata";
          };
          readonly = true;
          boot.order = 2;
        }
        {
          type = "file";
          device = "cdrom";
          driver = {
            name = "qemu";
            type = "raw";
          };
          source.file = /var/lib/libvirt/boot/virtio-win-0.1.285.iso;
          target = {
            dev = "sdb";
            bus = "sata";
          };
          readonly = true;
        }
      ];

      # PCI Passthrough (GPU)
      hostdevs = [
        {
          mode = "subsystem";
          type = "pci";
          managed = true;
          source.address = {
            domain = "0x0000";
            bus = "0x01";
            slot = "0x00";
            function = "0x0";
          };
        }
        {
          mode = "subsystem";
          type = "pci";
          managed = true;
          source.address = {
            domain = "0x0000";
            bus = "0x01";
            slot = "0x00";
            function = "0x1";
          };
        }
      ];

      # Shared Memory (Looking Glass)
      shmem = [
        {
          name = "looking-glass";
          model.type = "ivshmem-plain";
          size = {
            amount = 128;
            unit = "M";
          };
        }
      ];

      # Network
      interfaces = [
        {
          type = "network";
          source.network = "default";
          model.type = "virtio";
        }
      ];

      # Graphics
      graphics = [
        {
          type = "spice";
          listen = {
            type = "address";
            address = "127.0.0.1";
          };
          image.compression = "off";
        }
      ];

      # TPM
      tpm = {
        model = "tpm-crb";
        backend = {
          type = "emulator";
          version = "2.0";
        };
      };
    };

    autostart = false;
  };

  # ==========================================================================
  # Users
  # ==========================================================================
  # Users are defined as self-contained modules in users/ directory
  # and composed in flake.nix via: users = with self.users; [ draxel ];
}
