# Declarative Virtual Machine Management
#
# Provides NixOS-native VM definitions using libvirt.
# Supports multiple VMs with proper submodule types.
# Automatically integrates with VFIO module for GPU passthrough.
#
# Usage:
#   virtualisation.vms.win11 = {
#     type = "windows-gaming";
#     memory = 32768;
#     cpu = { cores = 6; threads = 2; };
#     gpu = {
#       enable = true;
#       pciId = "10de:2782";           # For VFIO kernel binding
#       audioPciId = "10de:22bc";
#       address = "0000:01:00.0";       # For libvirt XML
#       audioAddress = "0000:01:00.1";
#     };
#   };
#
# When gpu.enable = true, this module automatically derives VFIO settings:
#   - gpuPciIds from gpu.pciId/audioPciId
#   - gpuPciAddresses from gpu.address/audioAddress
#   - lookingGlass.shmSize from lookingGlass.size
#
# VFIO must be explicitly enabled (e.g., in a boot specialisation).
# Use modules.vfio.enable = true to activate GPU isolation.
#
{ config, lib, pkgs, ... }:

let
  # Use the libvirt helpers from extended lib (defined in lib/default.nix)
  lv = lib.libvirt;

  # ===========================================================================
  # Submodule: CPU Configuration
  # ===========================================================================
  cpuSubmodule = lib.types.submodule {
    options = {
      cores = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Number of CPU cores";
      };

      threads = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "Threads per core";
      };

      pinning = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable CPU pinning for performance";
        };

        startCpu = lib.mkOption {
          type = lib.types.int;
          default = 4;
          description = "First host CPU to pin to (reserves 0-3 for host)";
        };

        emulatorCpus = lib.mkOption {
          type = lib.types.str;
          default = "0-3";
          description = "CPUs for QEMU emulator threads";
        };
      };
    };
  };

  # ===========================================================================
  # Submodule: GPU Passthrough
  # ===========================================================================
  gpuSubmodule = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable GPU passthrough";
      };

      # PCI IDs for VFIO kernel binding (vendor:device format)
      pciId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "10de:2782";
        description = "GPU vendor:device ID for VFIO binding (find with: lspci -nn | grep -i nvidia)";
      };

      audioPciId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "10de:22bc";
        description = "GPU audio vendor:device ID for VFIO binding";
      };

      # PCI addresses for libvirt XML
      address = lib.mkOption {
        type = lib.types.nullOr lv.types.pciAddress;
        default = null;
        example = "0000:01:00.0";
        description = "GPU PCI address for libvirt (find with: lspci -D | grep -i nvidia)";
      };

      audioAddress = lib.mkOption {
        type = lib.types.nullOr lv.types.pciAddress;
        default = null;
        example = "0000:01:00.1";
        description = "GPU audio PCI address for libvirt";
      };
    };
  };

  # ===========================================================================
  # Submodule: Hugepages
  # ===========================================================================
  hugepagesSubmodule = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use 1GB hugepages for VM memory";
      };

      count = lib.mkOption {
        type = lib.types.int;
        default = 32;
        description = "Number of 1GB hugepages to allocate";
      };
    };
  };

  # ===========================================================================
  # Submodule: Storage
  # ===========================================================================
  storageSubmodule = lib.types.submodule ({ config, ... }: {
    options = {
      disk = lib.mkOption {
        type = lib.types.str;
        description = "Path to VM disk image";
      };

      size = lib.mkOption {
        type = lib.types.str;
        default = "256G";
        description = "Disk size (for creation)";
      };

      windowsIso = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to Windows ISO";
      };

      virtioIso = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to VirtIO drivers ISO";
      };
    };
  });

  # ===========================================================================
  # Submodule: Network
  # ===========================================================================
  networkSubmodule = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lv.types.networkType;
        default = "nat";
        description = ''
          Network type:
          - nat: Uses libvirt's default network (virbr0). Works out of the box.
                 VMs can access internet but are isolated from host network.
          - bridge: Uses a host bridge (br0). VMs get IPs from your router.
                    Requires modules.networking.bridge.enable = true
          - macvtap: Direct NIC attachment. No bridge needed, no rebuild for
                     interface changes. VMs get IPs from router.
          - user: SLIRP networking. Slowest but simplest.
        '';
      };

      bridge = lib.mkOption {
        type = lib.types.str;
        default = "br0";
        description = "Bridge name (when type = bridge)";
      };

      interface = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "enp6s0";
        description = ''
          Physical interface for macvtap networking.
          Find yours with: ip link | grep -E '^[0-9]+:' | grep -v 'lo\|vir\|docker'
          Only used when type = macvtap.
        '';
      };

      macvtapMode = lib.mkOption {
        type = lib.types.enum [ "bridge" "vepa" "private" "passthrough" ];
        default = "bridge";
        description = ''
          Macvtap mode (only used when type = macvtap):
          - bridge: VMs can talk to each other and network, but NOT to host
          - vepa: Requires VEPA-capable switch, traffic goes through switch
          - private: VMs isolated from each other, only network access
          - passthrough: Exclusive NIC access, only one VM can use it
        '';
      };
    };
  };

  # ===========================================================================
  # Submodule: Looking Glass
  # ===========================================================================
  lookingGlassSubmodule = lib.types.submodule {
    options = {
      size = lib.mkOption {
        type = lib.types.int;
        default = 128;
        description = "KVMFR shared memory size in MB (128 for 4K)";
      };
    };
  };

  # ===========================================================================
  # Main VM Submodule
  # ===========================================================================
  vmSubmodule = lib.types.submodule ({ name, config, ... }: {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable this VM";
      };

      type = lib.mkOption {
        type = lib.types.enum [ "windows-gaming" "linux-server" ];
        default = "windows-gaming";
        description = "VM template type";
      };

      memory = lib.mkOption {
        type = lib.types.int;
        default = 8192;
        description = "Memory in MB";
      };

      vcpus = lib.mkOption {
        type = lib.types.int;
        default = 8;
        description = "Total vCPUs (cores * threads)";
      };

      cpu = lib.mkOption {
        type = cpuSubmodule;
        default = {};
        description = "CPU configuration";
      };

      gpu = lib.mkOption {
        type = gpuSubmodule;
        default = {};
        description = "GPU passthrough configuration";
      };

      hugepages = lib.mkOption {
        type = hugepagesSubmodule;
        default = {};
        description = "Hugepages configuration";
      };

      storage = lib.mkOption {
        type = storageSubmodule;
        default = {
          disk = "/var/lib/libvirt/images/${name}.qcow2";
        };
        description = "Storage configuration";
      };

      network = lib.mkOption {
        type = networkSubmodule;
        default = {};
        description = "Network configuration";
      };

      lookingGlass = lib.mkOption {
        type = lookingGlassSubmodule;
        default = {};
        description = "Looking Glass configuration";
      };

      graphics = lib.mkOption {
        type = lv.types.graphicsType;
        default = "spice";
        description = "Graphics output: spice, vnc, or none";
      };

      autostart = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Auto-start VM on boot";
      };
    };
  });

  # Enabled VMs
  enabledVMs = lib.filterAttrs (_: vm: vm.enable) config.virtualisation.vms;

  # Check if any VM uses hugepages
  anyHugepages = lib.any (vm: vm.hugepages.enable) (lib.attrValues enabledVMs);
  maxHugepages = lib.foldl' lib.max 0 (map (vm: vm.hugepages.count) (lib.filter (vm: vm.hugepages.enable) (lib.attrValues enabledVMs)));

  # GPU passthrough helpers
  gpuEnabledVMs = lib.filter (vm: vm.gpu.enable) (lib.attrValues enabledVMs);
  anyGpuPassthrough = gpuEnabledVMs != [];

  # Collect all GPU PCI IDs for VFIO kernel binding
  allGpuPciIds = lib.unique (lib.concatMap (vm:
    lib.optional (vm.gpu.pciId != null) vm.gpu.pciId ++
    lib.optional (vm.gpu.audioPciId != null) vm.gpu.audioPciId
  ) gpuEnabledVMs);

  # Collect all GPU PCI addresses for VFIO module
  allGpuPciAddresses = lib.unique (lib.concatMap (vm:
    lib.optional (vm.gpu.address != null) vm.gpu.address ++
    lib.optional (vm.gpu.audioAddress != null) vm.gpu.audioAddress
  ) gpuEnabledVMs);

  # Get max Looking Glass size from GPU-enabled VMs
  maxLookingGlassSize = lib.foldl' lib.max 128 (map (vm: vm.lookingGlass.size) gpuEnabledVMs);

in
{
  # ===========================================================================
  # Module Options
  # ===========================================================================

  options.virtualisation.vms = lib.mkOption {
    type = lib.types.attrsOf vmSubmodule;
    default = {};
    description = "Declarative virtual machine definitions";
    example = lib.literalExpression ''
      {
        win11 = {
          type = "windows-gaming";
          memory = 32768;
          vcpus = 12;
          cpu.cores = 6;
          gpu = {
            enable = true;
            pciId = "10de:2782";         # For VFIO kernel binding
            audioPciId = "10de:22bc";
            address = "0000:01:00.0";     # For libvirt XML
            audioAddress = "0000:01:00.1";
          };
          hugepages.enable = true;
        };
      }
    '';
  };

  # ===========================================================================
  # Module Configuration
  # ===========================================================================

  config = lib.mkIf (enabledVMs != {}) {
    # Assertions for network configuration
    assertions = lib.mapAttrsToList (name: vm: {
      assertion = vm.network.type != "macvtap" || vm.network.interface != "";
      message = ''
        VM '${name}' uses macvtap networking but network.interface is not set.
        Find your interface with: ip link | grep -E '^[0-9]+:' | grep -v 'lo\|vir\|docker'

        Example:
          virtualisation.vms.${name}.network = {
            type = "macvtap";
            interface = "enp6s0";
          };
      '';
    }) enabledVMs;

    # Ensure libvirt is available
    virtualisation.libvirtd.enable = lib.mkDefault true;

    # =========================================================================
    # VFIO Integration - derive settings from VM GPU configs
    # =========================================================================
    # NOTE: This only configures VFIO settings, does NOT auto-enable VFIO.
    # Enable VFIO explicitly with: modules.vfio.enable = true
    # (typically in a boot specialisation for dual-boot setups)
    modules.vfio = lib.mkIf anyGpuPassthrough {
      # Derive PCI IDs from VM configurations
      gpuPciIds = lib.mkDefault allGpuPciIds;
      gpuPciAddresses = lib.mkDefault allGpuPciAddresses;

      # Sync Looking Glass size from VM config
      lookingGlass.shmSize = lib.mkDefault maxLookingGlassSize;
    };

    # =========================================================================
    # Hugepages - configure if any VM uses them
    # =========================================================================
    boot.kernelParams = lib.mkIf anyHugepages [
      "hugepagesz=1G"
      "hugepages=${toString maxHugepages}"
      "transparent_hugepage=never"
    ];

    # =========================================================================
    # Libvirt XML Generation
    # =========================================================================
    environment.etc = lib.mapAttrs' (name: vm: {
      name = "libvirt/qemu/${name}.xml";
      value.text =
        if vm.type == "windows-gaming"
        then lv.builders.windowsGaming (vm // { inherit name; })
        else lv.builders.linuxServer (vm // { inherit name; });
    }) enabledVMs;

    # =========================================================================
    # VM Definition Services
    # =========================================================================
    systemd.services = lib.mapAttrs' (name: vm: {
      name = "libvirt-define-${name}";
      value = {
        description = "Define libvirt VM: ${name}";
        after = [ "libvirtd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.libvirt}/bin/virsh define /etc/libvirt/qemu/${name}.xml 2>/dev/null || true
          ${lib.optionalString vm.autostart ''
            ${pkgs.libvirt}/bin/virsh autostart ${name} 2>/dev/null || true
          ''}
        '';
      };
    }) enabledVMs;
  };
}
