# Declarative Libvirt Domain Management
#
# This module provides a declarative Nix interface for libvirt domain XML.
# It maps almost 1:1 to the libvirt XML schema for transparency.
#
# Usage:
#   virtualisation.vms.win11 = {
#     title = "Windows 11 Gaming";
#     memory.amount = 16384;
#     vcpu.count = 12;
#     devices.hostdevs = [ ... PCI passthrough ... ];
#   };
#
{ config, lib, pkgs, ... }:

let
  lv = lib.libvirt;

  # ===========================================================================
  # Submodule: Disk Device
  # ===========================================================================
  diskSubmodule = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.enum [ "file" "block" "dir" "network" ];
        default = "file";
        description = "Disk type";
      };

      device = lib.mkOption {
        type = lib.types.enum [ "disk" "cdrom" "floppy" "lun" ];
        default = "disk";
        description = "Device type";
      };

      driver = lib.mkOption {
        type = lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              default = "qemu";
              description = "Driver name";
            };

            type = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum [ "raw" "qcow2" "qed" "vdi" "vmdk" "vpc" ]);
              default = null;
              description = "Driver type (format)";
            };

            cache = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum [ "none" "writethrough" "writeback" "directsync" "unsafe" ]);
              default = null;
              description = "Cache mode";
            };

            io = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum [ "threads" "native" "io_uring" ]);
              default = null;
              description = "IO mode";
            };

            discard = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum [ "unmap" "ignore" ]);
              default = null;
              description = "Discard mode";
            };
          };
        };
        default = {};
        description = "Driver configuration";
      };

      source = lib.mkOption {
        type = lib.types.submodule {
          options = {
            file = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Path to disk file";
            };

            dev = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Block device path";
            };
          };
        };
        default = {};
        description = "Disk source";
      };

      size = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "100G";
        description = "Size for auto-created qcow2 disk (e.g., 100G, 500G, 1T)";
      };

      target = lib.mkOption {
        type = lib.types.submodule {
          options = {
            dev = lib.mkOption {
              type = lib.types.str;
              description = "Target device name (e.g., vda, sda)";
            };

            bus = lib.mkOption {
              type = lib.types.enum [ "virtio" "sata" "scsi" "ide" "usb" "fdc" ];
              default = "virtio";
              description = "Bus type";
            };
          };
        };
        description = "Target configuration";
      };

      readonly = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Make disk readonly";
      };

      boot = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            order = lib.mkOption {
              type = lib.types.int;
              description = "Boot order";
            };
          };
        });
        default = null;
        description = "Boot configuration";
      };
    };
  };

  # ===========================================================================
  # Submodule: Host Device (PCI/USB Passthrough)
  # ===========================================================================
  hostdevSubmodule = lib.types.submodule {
    options = {
      mode = lib.mkOption {
        type = lib.types.enum [ "subsystem" "capabilities" ];
        default = "subsystem";
        description = "Passthrough mode";
      };

      type = lib.mkOption {
        type = lib.types.enum [ "pci" "usb" "scsi" "storage" "misc" "net" ];
        description = "Device type";
      };

      managed = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether libvirt manages device binding";
      };

      source = lib.mkOption {
        type = lib.types.submodule {
          options = {
            address = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  domain = lib.mkOption {
                    type = lib.types.str;
                    default = "0x0000";
                    description = "PCI domain";
                  };

                  bus = lib.mkOption {
                    type = lib.types.str;
                    description = "PCI bus (e.g., 0x01)";
                  };

                  slot = lib.mkOption {
                    type = lib.types.str;
                    description = "PCI slot (e.g., 0x00)";
                  };

                  function = lib.mkOption {
                    type = lib.types.str;
                    description = "PCI function (e.g., 0x0)";
                  };
                };
              });
              default = null;
              description = "PCI address";
            };
          };
        };
        default = {};
        description = "Device source";
      };
    };
  };

  # ===========================================================================
  # Submodule: Shared Memory Device
  # ===========================================================================
  shmemSubmodule = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Shared memory name";
      };

      model = lib.mkOption {
        type = lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [ "ivshmem-plain" "ivshmem-doorbell" "ivshmem" ];
              default = "ivshmem-plain";
              description = "Shared memory model";
            };
          };
        };
        default = {};
        description = "Model configuration";
      };

      size = lib.mkOption {
        type = lib.types.submodule {
          options = {
            amount = lib.mkOption {
              type = lib.types.int;
              description = "Size amount";
            };

            unit = lib.mkOption {
              type = lib.types.enum [ "B" "K" "M" "G" ];
              default = "M";
              description = "Size unit";
            };
          };
        };
        description = "Shared memory size";
      };
    };
  };

  # ===========================================================================
  # Submodule: Network Interface
  # ===========================================================================
  interfaceSubmodule = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.enum [ "network" "bridge" "user" "ethernet" "direct" ];
        description = "Interface type";
      };

      source = lib.mkOption {
        type = lib.types.submodule {
          options = {
            network = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Network name (for type=network)";
            };

            bridge = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Bridge name (for type=bridge)";
            };

            dev = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Device name (for type=direct)";
            };

            mode = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum [ "vepa" "bridge" "private" "passthrough" ]);
              default = null;
              description = "Mode (for type=direct/macvtap)";
            };
          };
        };
        default = {};
        description = "Network source";
      };

      model = lib.mkOption {
        type = lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [ "virtio" "e1000" "rtl8139" ];
              default = "virtio";
              description = "Network model";
            };
          };
        };
        default = {};
        description = "Network model";
      };
    };
  };

  # ===========================================================================
  # Submodule: Graphics
  # ===========================================================================
  graphicsSubmodule = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.enum [ "spice" "vnc" "sdl" "rdp" "desktop" "none" ];
        description = "Graphics type";
      };

      listen = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [ "address" "network" "socket" "none" ];
              default = "address";
              description = "Listen type";
            };

            address = lib.mkOption {
              type = lib.types.str;
              default = "127.0.0.1";
              description = "Listen address";
            };
          };
        });
        default = null;
        description = "Listen configuration";
      };

      image = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            compression = lib.mkOption {
              type = lib.types.enum [ "auto_glz" "auto_lz" "quic" "glz" "lz" "off" ];
              default = "off";
              description = "Image compression";
            };
          };
        });
        default = null;
        description = "Image configuration";
      };
    };
  };

  # ===========================================================================
  # Submodule: TPM
  # ===========================================================================
  tpmSubmodule = lib.types.submodule {
    options = {
      model = lib.mkOption {
        type = lib.types.enum [ "tpm-tis" "tpm-crb" ];
        default = "tpm-crb";
        description = "TPM model";
      };

      backend = lib.mkOption {
        type = lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [ "passthrough" "emulator" ];
              default = "emulator";
              description = "Backend type";
            };

            version = lib.mkOption {
              type = lib.types.enum [ "1.2" "2.0" ];
              default = "2.0";
              description = "TPM version";
            };
          };
        };
        default = {};
        description = "TPM backend";
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

      title = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "Human-readable title";
      };

      description = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "VM description";
      };

      memory = lib.mkOption {
        type = lib.types.submodule {
          options = {
            amount = lib.mkOption {
              type = lib.types.int;
              default = 8192;
              description = "Memory in MiB";
            };

            unit = lib.mkOption {
              type = lib.types.str;
              default = "MiB";
              description = "Memory unit";
            };

            hugepages = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = "Use hugepages";
                  };

                  size = lib.mkOption {
                    type = lib.types.int;
                    default = 1;
                    description = "Hugepage size in GB";
                  };

                  count = lib.mkOption {
                    type = lib.types.int;
                    default = 0;
                    description = "Number of hugepages";
                  };
                };
              };
              default = {};
              description = "Hugepages configuration";
            };
          };
        };
        default = {};
        description = "Memory configuration";
      };

      vcpu = lib.mkOption {
        type = lib.types.submodule {
          options = {
            count = lib.mkOption {
              type = lib.types.int;
              default = 4;
              description = "Number of vCPUs";
            };

            placement = lib.mkOption {
              type = lib.types.enum [ "static" "auto" ];
              default = "static";
              description = "CPU placement";
            };
          };
        };
        default = {};
        description = "vCPU configuration";
      };

      cpu = lib.mkOption {
        type = lib.types.submodule {
          options = {
            mode = lib.mkOption {
              type = lib.types.enum [ "host-passthrough" "host-model" "custom" ];
              default = "host-passthrough";
              description = "CPU mode";
            };

            topology = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  sockets = lib.mkOption {
                    type = lib.types.int;
                    default = 1;
                    description = "Number of sockets";
                  };

                  dies = lib.mkOption {
                    type = lib.types.int;
                    default = 1;
                    description = "Dies per socket";
                  };

                  cores = lib.mkOption {
                    type = lib.types.int;
                    description = "Cores per die";
                  };

                  threads = lib.mkOption {
                    type = lib.types.int;
                    description = "Threads per core";
                  };
                };
              });
              default = null;
              description = "CPU topology";
            };

            feature = lib.mkOption {
              type = lib.types.listOf (lib.types.submodule {
                options = {
                  policy = lib.mkOption {
                    type = lib.types.enum [ "force" "require" "optional" "disable" "forbid" ];
                    description = "Feature policy";
                  };

                  name = lib.mkOption {
                    type = lib.types.str;
                    description = "Feature name (e.g., hypervisor, topoext, invtsc)";
                  };
                };
              });
              default = [];
              description = "CPU features to enable/disable";
            };
          };
        };
        default = {};
        description = "CPU configuration";
      };

      cputune = lib.mkOption {
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            vcpupin = lib.mkOption {
              type = lib.types.listOf (lib.types.submodule {
                options = {
                  vcpu = lib.mkOption {
                    type = lib.types.int;
                    description = "vCPU number";
                  };

                  cpuset = lib.mkOption {
                    type = lib.types.str;
                    description = "Host CPU set (e.g., '4' or '4-5')";
                  };
                };
              });
              default = [];
              description = "vCPU pinning";
            };

            emulatorpin = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  cpuset = lib.mkOption {
                    type = lib.types.str;
                    description = "CPU set for emulator threads";
                  };
                };
              });
              default = null;
              description = "Emulator thread pinning";
            };
          };
        });
        default = null;
        description = "CPU tuning";
      };

      os = lib.mkOption {
        type = lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [ "hvm" "linux" "exe" ];
              default = "hvm";
              description = "OS type";
            };

            arch = lib.mkOption {
              type = lib.types.enum [ "x86_64" "i686" "aarch64" ];
              default = "x86_64";
              description = "Architecture";
            };

            machine = lib.mkOption {
              type = lib.types.str;
              default = "pc-q35-8.2";
              description = "Machine type";
            };

            firmware = lib.mkOption {
              type = lib.types.enum [ "bios" "efi" ];
              default = "efi";
              description = "Firmware type";
            };

            loader = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  readonly = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = "Readonly loader";
                  };

                  type = lib.mkOption {
                    type = lib.types.enum [ "rom" "pflash" ];
                    default = "pflash";
                    description = "Loader type";
                  };

                  secure = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = "Secure boot";
                  };

                  path = lib.mkOption {
                    type = lib.types.str;
                    description = "Path to loader";
                  };
                };
              });
              default = null;
              description = "UEFI loader configuration";
            };

            nvram = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  template = lib.mkOption {
                    type = lib.types.str;
                    description = "NVRAM template path";
                  };

                  path = lib.mkOption {
                    type = lib.types.str;
                    description = "NVRAM storage path";
                  };
                };
              });
              default = null;
              description = "NVRAM configuration";
            };
          };
        };
        default = {};
        description = "OS configuration";
      };

      features = lib.mkOption {
        type = lib.types.submodule {
          options = {
            acpi = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable ACPI";
            };

            apic = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable APIC";
            };

            pae = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable PAE";
            };

            hyperv = lib.mkOption {
              type = lib.types.nullOr (lib.types.attrsOf (lib.types.submodule {
                options = {
                  state = lib.mkOption {
                    type = lib.types.enum [ "on" "off" ];
                    default = "on";
                    description = "Feature state";
                  };

                  retries = lib.mkOption {
                    type = lib.types.nullOr lib.types.int;
                    default = null;
                    description = "Retries (for spinlocks)";
                  };

                  value = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Value (for vendor_id)";
                  };
                };
              }));
              default = null;
              description = "Hyper-V enlightenments";
            };

            kvm = lib.mkOption {
              type = lib.types.nullOr (lib.types.attrsOf (lib.types.submodule {
                options = {
                  state = lib.mkOption {
                    type = lib.types.enum [ "on" "off" ];
                    default = "on";
                    description = "Feature state";
                  };
                };
              }));
              default = null;
              description = "KVM features";
            };

            vmport = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  state = lib.mkOption {
                    type = lib.types.enum [ "on" "off" ];
                    description = "VMware port state";
                  };
                };
              });
              default = null;
              description = "VMware I/O port";
            };

            ioapic = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  driver = lib.mkOption {
                    type = lib.types.enum [ "kvm" "qemu" ];
                    default = "kvm";
                    description = "IOAPIC driver";
                  };
                };
              });
              default = null;
              description = "IOAPIC configuration";
            };
          };
        };
        default = {};
        description = "VM features";
      };

      clock = lib.mkOption {
        type = lib.types.submodule {
          options = {
            offset = lib.mkOption {
              type = lib.types.enum [ "utc" "localtime" "timezone" "variable" ];
              default = "utc";
              description = "Clock offset";
            };

            timers = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submodule {
                options = {
                  present = lib.mkOption {
                    type = lib.types.nullOr lib.types.bool;
                    default = null;
                    description = "Timer present";
                  };

                  tickpolicy = lib.mkOption {
                    type = lib.types.nullOr (lib.types.enum [ "delay" "catchup" "merge" "discard" ]);
                    default = null;
                    description = "Tick policy";
                  };
                };
              });
              default = {};
              description = "Clock timers";
            };
          };
        };
        default = {};
        description = "Clock configuration";
      };

      devices = lib.mkOption {
        type = lib.types.submodule {
          options = {
            disks = lib.mkOption {
              type = lib.types.listOf diskSubmodule;
              default = [];
              description = "Disk devices";
            };

            hostdevs = lib.mkOption {
              type = lib.types.listOf hostdevSubmodule;
              default = [];
              description = "Host devices (PCI/USB passthrough)";
            };

            shmem = lib.mkOption {
              type = lib.types.listOf shmemSubmodule;
              default = [];
              description = "Shared memory devices";
            };

            interfaces = lib.mkOption {
              type = lib.types.listOf interfaceSubmodule;
              default = [];
              description = "Network interfaces";
            };

            graphics = lib.mkOption {
              type = lib.types.listOf graphicsSubmodule;
              default = [];
              description = "Graphics devices";
            };

            tpm = lib.mkOption {
              type = lib.types.nullOr tpmSubmodule;
              default = null;
              description = "TPM device";
            };
          };
        };
        default = {};
        description = "Devices";
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
  anyHugepages = lib.any (vm: vm.memory.hugepages.enable) (lib.attrValues enabledVMs);
  maxHugepages = lib.foldl' lib.max 0 (map (vm: vm.memory.hugepages.count) (lib.filter (vm: vm.memory.hugepages.enable) (lib.attrValues enabledVMs)));

in
{
  # ===========================================================================
  # Module Options
  # ===========================================================================

  options.virtualisation.vms = lib.mkOption {
    type = lib.types.attrsOf vmSubmodule;
    default = {};
    description = "Declarative libvirt domain definitions";
  };

  # ===========================================================================
  # Module Configuration
  # ===========================================================================

  config = lib.mkIf (enabledVMs != {}) {
    # Ensure libvirt is available
    virtualisation.libvirtd.enable = lib.mkDefault true;

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
      value.text = lv.generateDomainXML (vm // { inherit name; });
    }) enabledVMs;

    # =========================================================================
    # VM Definition Services
    # =========================================================================
    systemd.services = lib.mapAttrs' (name: vm:
      let
        # Extract all disk files that need to be created
        diskFiles = lib.filter (disk:
          disk.type == "file" &&
          disk.device == "disk" &&
          disk.source.file != null &&
          (disk.driver.type == "qcow2" || disk.driver.type == null)
        ) vm.devices.disks;

        # Generate disk creation commands
        createDisksScript = lib.concatMapStringsSep "\n" (disk:
          let
            diskPath = toString disk.source.file;
            diskDir = dirOf diskPath;
            diskSize = if disk.size != null then disk.size else "100G";
          in
          ''
            # Create ${diskPath} if it doesn't exist
            if [ ! -f "${diskPath}" ]; then
              echo "Creating qcow2 disk: ${diskPath} (${diskSize})"
              mkdir -p "${diskDir}"
              ${pkgs.qemu}/bin/qemu-img create -f qcow2 "${diskPath}" ${diskSize}
            fi
          ''
        ) diskFiles;
      in
    {
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
          # Create disk images if they don't exist
          ${createDisksScript}

          # Define VM in libvirt
          ${pkgs.libvirt}/bin/virsh define /etc/libvirt/qemu/${name}.xml 2>/dev/null || true
          ${lib.optionalString vm.autostart ''
            ${pkgs.libvirt}/bin/virsh autostart ${name} 2>/dev/null || true
          ''}
        '';
      };
    }) enabledVMs;
  };
}
