# Windows 11 Gaming VM
# GPU passthrough configuration for gaming with Looking Glass
{
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
      # Note: stimer direct mode requires nested XML which isn't supported yet
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
    smm = { state = "on"; };  # System Management Mode (required for Secure Boot)
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
      # Uncomment for installation:
      # /var/lib/libvirt/boot/virtio-win-0.1.285.iso
      # /var/lib/libvirt/boot/Win11_25H2_English_x64.iso

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
}
