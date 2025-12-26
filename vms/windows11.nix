# Declarative Windows 11 VM with GPU passthrough
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.vms.windows11;
  vfioCfg = config.modules.vfio;
  userCfg = config.modules.users;

  # Parse PCI address (0000:01:00.0) into components
  parsePciAddr = addr: let
    stripped = lib.removePrefix "0000:" addr;
    parts = lib.splitString ":" stripped;
    bus = builtins.head parts;
    rest = builtins.elemAt parts 1;
    devFn = lib.splitString "." rest;
  in {
    bus = "0x${bus}";
    slot = "0x${builtins.head devFn}";
    function = "0x${builtins.elemAt devFn 1}";
  };

  gpuAddr = if (builtins.length vfioCfg.gpuPciAddresses) > 0
    then parsePciAddr (builtins.head vfioCfg.gpuPciAddresses)
    else { bus = "0x01"; slot = "0x00"; function = "0x0"; };

  audioAddr = if (builtins.length vfioCfg.gpuPciAddresses) > 1
    then parsePciAddr (builtins.elemAt vfioCfg.gpuPciAddresses 1)
    else { bus = "0x01"; slot = "0x00"; function = "0x1"; };
in
{
  options.modules.vms.windows11 = {
    enable = lib.mkEnableOption "Windows 11 VM";

    name = lib.mkOption {
      type = lib.types.str;
      default = "win11";
      description = "VM name";
    };

    memory = lib.mkOption {
      type = lib.types.int;
      default = 32768;  # 32GB
      description = "Memory in MB";
    };

    vcpus = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "Number of vCPUs (threads)";
    };

    cores = lib.mkOption {
      type = lib.types.int;
      default = 6;
      description = "Number of physical cores";
    };

    diskPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/libvirt/images/win11.qcow2";
      description = "Path to VM disk image";
    };

    diskSize = lib.mkOption {
      type = lib.types.str;
      default = "256G";
      description = "Disk size for new VM";
    };

    isoPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/libvirt/images/Win11.iso";
      description = "Path to Windows 11 ISO";
    };

    virtioIsoPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/libvirt/images/virtio-win.iso";
      description = "Path to VirtIO drivers ISO";
    };

    lookingGlassSize = lib.mkOption {
      type = lib.types.int;
      default = 128;  # MB - enough for 4K
      description = "KVMFR shared memory size in MB";
    };

    hugepages = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use 1GB hugepages for VM memory";
    };

    hugepagesCount = lib.mkOption {
      type = lib.types.int;
      default = 32;  # 32GB
      description = "Number of 1GB hugepages to allocate";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure libvirt is enabled
    modules.virtualization.libvirt.enable = true;

    # Configure hugepages for VM performance
    boot.kernelParams = lib.mkIf cfg.hugepages [
      "hugepagesz=1G"
      "hugepages=${toString cfg.hugepagesCount}"
      "transparent_hugepage=never"
    ];

    # Create VM XML definition file
    environment.etc."libvirt/qemu/${cfg.name}.xml".text = ''
      <domain type='kvm'>
        <name>${cfg.name}</name>
        <memory unit='MiB'>${toString cfg.memory}</memory>
        <currentMemory unit='MiB'>${toString cfg.memory}</currentMemory>
        <vcpu placement='static'>${toString cfg.vcpus}</vcpu>

        <!-- CPU topology: 7800X3D single CCD layout -->
        <!-- Reserve cores 0-1 for host, cores 2-7 for VM -->
        <cpu mode='host-passthrough' check='none' migratable='off'>
          <topology sockets='1' dies='1' cores='${toString cfg.cores}' threads='2'/>
          <cache mode='passthrough'/>
          <feature policy='require' name='topoext'/>
          <feature policy='disable' name='hypervisor'/>
        </cpu>

        <!-- CPU pinning for optimal performance -->
        <cputune>
          <!-- Pin vCPUs to physical cores 2-7 (threads 4-15) -->
          ${lib.concatStringsSep "\n          " (lib.genList (i: "<vcpupin vcpu='${toString i}' cpuset='${toString (4 + i)}'/>") cfg.vcpus)}
          <!-- Emulator and I/O on host cores 0-1 -->
          <emulatorpin cpuset='0-3'/>
        </cputune>

        ${lib.optionalString cfg.hugepages ''
        <memoryBacking>
          <hugepages>
            <page size='1048576' unit='KiB'/>
          </hugepages>
        </memoryBacking>
        ''}

        <os>
          <type arch='x86_64' machine='pc-q35-8.2'>hvm</type>
          <loader readonly='yes' secure='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.ms.fd</loader>
          <nvram template='/run/libvirt/nix-ovmf/OVMF_VARS.ms.fd'>/var/lib/libvirt/qemu/nvram/${cfg.name}_VARS.fd</nvram>
          <boot dev='hd'/>
          <bootmenu enable='yes'/>
        </os>

        <features>
          <acpi/>
          <apic/>
          <hyperv mode='custom'>
            <relaxed state='on'/>
            <vapic state='on'/>
            <spinlocks state='on' retries='8191'/>
            <vpindex state='on'/>
            <runtime state='on'/>
            <synic state='on'/>
            <stimer state='on'/>
            <frequencies state='on'/>
          </hyperv>
          <kvm>
            <hidden state='on'/>
          </kvm>
          <vmport state='off'/>
          <smm state='on'/>
          <ioapic driver='kvm'/>
        </features>

        <clock offset='localtime'>
          <timer name='rtc' tickpolicy='catchup'/>
          <timer name='pit' tickpolicy='delay'/>
          <timer name='hpet' present='no'/>
          <timer name='hypervclock' present='yes'/>
          <timer name='tsc' present='yes' mode='native'/>
        </clock>

        <on_poweroff>destroy</on_poweroff>
        <on_reboot>restart</on_reboot>
        <on_crash>destroy</on_crash>

        <pm>
          <suspend-to-mem enabled='no'/>
          <suspend-to-disk enabled='no'/>
        </pm>

        <devices>
          <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>

          <!-- VirtIO disk -->
          <disk type='file' device='disk'>
            <driver name='qemu' type='qcow2' cache='none' io='native' discard='unmap'/>
            <source file='${cfg.diskPath}'/>
            <target dev='vda' bus='virtio'/>
          </disk>

          <!-- Windows ISO (remove after install) -->
          <disk type='file' device='cdrom'>
            <driver name='qemu' type='raw'/>
            <source file='${cfg.isoPath}'/>
            <target dev='sda' bus='sata'/>
            <readonly/>
          </disk>

          <!-- VirtIO drivers ISO -->
          <disk type='file' device='cdrom'>
            <driver name='qemu' type='raw'/>
            <source file='${cfg.virtioIsoPath}'/>
            <target dev='sdb' bus='sata'/>
            <readonly/>
          </disk>

          <!-- TPM 2.0 for Windows 11 -->
          <tpm model='tpm-tis'>
            <backend type='emulator' version='2.0'/>
          </tpm>

          <!-- GPU passthrough -->
          <hostdev mode='subsystem' type='pci' managed='yes'>
            <source>
              <address domain='0x0000' bus='${gpuAddr.bus}' slot='${gpuAddr.slot}' function='${gpuAddr.function}'/>
            </source>
            <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0' multifunction='on'/>
          </hostdev>

          <!-- GPU Audio passthrough -->
          <hostdev mode='subsystem' type='pci' managed='yes'>
            <source>
              <address domain='0x0000' bus='${audioAddr.bus}' slot='${audioAddr.slot}' function='${audioAddr.function}'/>
            </source>
            <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x1'/>
          </hostdev>

          <!-- KVMFR for Looking Glass -->
          <shmem name='looking-glass'>
            <model type='ivshmem-plain'/>
            <size unit='M'>${toString cfg.lookingGlassSize}</size>
          </shmem>

          <!-- Network: bridged -->
          <interface type='bridge'>
            <source bridge='br0'/>
            <model type='virtio'/>
          </interface>

          <!-- Spice for fallback/setup -->
          <graphics type='spice' autoport='yes'>
            <listen type='address' address='127.0.0.1'/>
            <gl enable='no'/>
          </graphics>

          <!-- USB controllers for passthrough -->
          <controller type='usb' model='qemu-xhci' ports='15'/>

          <!-- Console -->
          <serial type='pty'>
            <target port='0'/>
          </serial>
          <console type='pty'>
            <target type='serial' port='0'/>
          </console>

          <!-- Disable memballoon for performance -->
          <memballoon model='none'/>
        </devices>
      </domain>
    '';

    # Define the VM with virsh on boot
    systemd.services."libvirt-define-${cfg.name}" = {
      description = "Define ${cfg.name} VM";
      after = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.libvirt}/bin/virsh define /etc/libvirt/qemu/${cfg.name}.xml 2>/dev/null || true
      '';
    };
  };
}
