# =============================================================================
# VFIO GPU Passthrough Configuration
# =============================================================================
#
# This module enables GPU passthrough to virtual machines using VFIO.
#
# BOOT MODES:
# -----------
# 1. VFIO (Default): NVIDIA GPU isolated for VM passthrough
#    - NVIDIA drivers blacklisted
#    - vfio-pci binds to NVIDIA GPU at boot
#    - AMD GPU is primary display
#    - Use for: Windows gaming VM, GPU compute VM
#
# 2. Normal (Specialisation): NVIDIA GPU on host
#    - NVIDIA drivers loaded
#    - AMD GPU still available
#    - Use for: CUDA development, Docker GPU, native Linux gaming
#
# To switch modes: Select at boot menu or `sudo bootctl set-default`
#
# FEATURES:
# ---------
# - VFIO kernel modules and PCI device binding
# - CPU core isolation for near-native VM performance
# - Hugepages for low-latency memory access
# - Looking Glass for low-latency VM display
# - Scream for low-latency VM audio
# - evdev passthrough for keyboard/mouse sharing
# - libvirtd with QEMU/KVM
#
# REQUIREMENTS:
# -------------
# - AMD CPU with IOMMU (AMD-Vi)
# - Motherboard with good IOMMU groups
# - Two GPUs (one for host, one for VM)
#
# =============================================================================

{ config, pkgs, lib, vars, ... }:

{
  # ===========================================================================
  # Kernel Parameters for VFIO
  # ===========================================================================

  boot.kernelParams = [
    # -------------------------------------------------------------------------
    # IOMMU Configuration
    # -------------------------------------------------------------------------

    # amd_iommu=on
    # Enable AMD's IOMMU (I/O Memory Management Unit).
    # REQUIRED for VFIO - allows the hypervisor to isolate device memory.
    # Intel equivalent: intel_iommu=on
    "amd_iommu=on"

    # iommu=pt
    # IOMMU passthrough mode - only translate for devices that need it.
    # Improves performance for devices NOT passed through.
    # Without this: All device I/O goes through IOMMU translation (slower).
    "iommu=pt"

    # -------------------------------------------------------------------------
    # KVM Configuration
    # -------------------------------------------------------------------------

    # kvm.ignore_msrs=1
    # Ignore unhandled Model-Specific Registers (MSRs).
    # Some Windows drivers read MSRs that KVM doesn't emulate.
    # Without this: VM may crash on certain MSR accesses.
    "kvm.ignore_msrs=1"

    # kvm.report_ignored_msrs=0
    # Don't spam dmesg with ignored MSR warnings.
    # These are expected and harmless, just noisy.
    "kvm.report_ignored_msrs=0"

    # -------------------------------------------------------------------------
    # CPU Isolation (Performance Optimization)
    # -------------------------------------------------------------------------
    # Isolates CPU cores from the Linux scheduler for VM-exclusive use.
    # This gives the VM dedicated cores with no host interference.
    #
    # For Ryzen 9800X3D (8 cores, 16 threads):
    # - Cores 0-3 (threads 0-3, 8-11): Host
    # - Cores 4-7 (threads 4-7, 12-15): VM
    #
    # Check your topology with: lscpu --extended

    # isolcpus: Remove cores from scheduler
    # These cores won't run any host processes.
    "isolcpus=4-7,12-15"

    # nohz_full: Disable timer ticks on isolated cores
    # Reduces latency spikes from kernel housekeeping.
    "nohz_full=4-7,12-15"

    # rcu_nocbs: Move RCU callbacks off isolated cores
    # Prevents kernel read-copy-update work from interrupting VM.
    "rcu_nocbs=4-7,12-15"

    # -------------------------------------------------------------------------
    # Hugepages (Memory Performance)
    # -------------------------------------------------------------------------
    # Pre-allocate large memory pages for VM use.
    # Benefits:
    # - Reduced TLB misses (better memory access performance)
    # - Memory is locked and can't be swapped
    # - Lower latency for memory-intensive workloads
    #
    # 1GB pages are best for VMs with lots of RAM.
    # 16 pages × 1GB = 16GB reserved for VM

    "default_hugepagesz=1G"  # Default hugepage size
    "hugepagesz=1G"          # Available hugepage size
    "hugepages=16"           # Number of pages to allocate

    # -------------------------------------------------------------------------
    # VFIO PCI Device Binding
    # -------------------------------------------------------------------------
    # Tell vfio-pci driver to claim these devices at boot.
    # Format: vendor:device (from lspci -nn)
    # The GPU will be bound to vfio-pci instead of nvidia/nouveau.

  ] ++ lib.optionals (vars.gpu.vfioIds != []) [
    # Configured in vars.nix: vars.gpu.vfioIds
    # Example: [ "10de:2c05" "10de:22e9" ] for RTX 5070 Ti + Audio
    "vfio-pci.ids=${lib.concatStringsSep "," vars.gpu.vfioIds}"
  ];

  # ===========================================================================
  # Kernel Modules - VFIO Mode (Default Boot)
  # ===========================================================================

  # Load VFIO modules early in initramfs
  # This ensures vfio-pci claims the GPU before nvidia driver loads.
  # Order matters: vfio_pci must be ready before PCI enumeration.
  boot.initrd.kernelModules = lib.mkAfter [
    "vfio_pci"         # PCI device passthrough driver
    "vfio"             # Core VFIO framework
    "vfio_iommu_type1" # IOMMU backend for VFIO
  ];

  # KVM module for virtualization
  boot.kernelModules = [ "kvm-amd" ];

  # Blacklist NVIDIA drivers so they don't grab the GPU
  # The GPU should only be accessible via VFIO for passthrough.
  boot.blacklistedKernelModules = [
    "nouveau"        # Open source NVIDIA driver
    "nvidia"         # Proprietary NVIDIA driver
    "nvidia_modeset" # NVIDIA modesetting
    "nvidia_uvm"     # NVIDIA Unified Memory
    "nvidia_drm"     # NVIDIA DRM (for Wayland)
  ];

  # ===========================================================================
  # KVMFR - Looking Glass Shared Memory
  # ===========================================================================
  # Looking Glass displays the VM's screen with minimal latency.
  # KVMFR (KVM FrameRelay) provides shared memory between host and VM.
  #
  # The VM captures frames and writes to shared memory.
  # Looking Glass client reads from shared memory and displays.
  # Result: Near-native display latency (< 1 frame).
  #
  # Size calculation: Width × Height × 4 (BGRA) × 2 (double buffer) + overhead
  # - 1080p:       1920×1080×4×2 = ~16MB
  # - 1440p:       2560×1440×4×2 = ~29MB
  # - 4K:          3840×2160×4×2 = ~66MB
  # - 5120x1440:   5120×1440×4×2 = ~59MB
  # At 240Hz you want extra buffer headroom for smooth frame capture.
  # IMPORTANT: This MUST match your VM's IVSHMEM device size!

  boot.extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
  boot.extraModprobeConfig = ''
    # 256MB for ultrawide 5120x1440@240Hz with headroom
    options kvmfr static_size_mb=256
  '';

  # ===========================================================================
  # Virtualization - libvirtd
  # ===========================================================================
  # libvirtd manages VMs via QEMU/KVM.

  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      package = pkgs.qemu_kvm;  # KVM-enabled QEMU

      # Software TPM for Windows 11
      # Windows 11 requires TPM 2.0 - this emulates one.
      swtpm.enable = true;

      # QEMU configuration
      verbatimConfig = ''
        # Run QEMU as your user (not root) for easier permissions
        user = "${vars.primaryUser}"
        group = "libvirtd"

        # Hugepages memory backing
        # VMs will use the pre-allocated hugepages for memory.
        memory_backing_dir = "/dev/hugepages"

        # Disable namespace isolation
        # Required for some device passthrough scenarios.
        namespaces = []

        # Device access whitelist
        # QEMU needs access to these devices for passthrough.
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm",
          "/dev/vfio/vfio",
          "/dev/vfio/*",
          "/dev/input/event*",
          "/dev/input/by-id/*",
          "/dev/input/by-path/*",
          "/dev/input/vm-keyboard",
          "/dev/input/vm-mouse"
        ]

        # Don't drop capabilities
        # Needed for some advanced passthrough features.
        clear_emulation_capabilities = 0
      '';
    };
  };

  # Virt-manager GUI for VM management
  programs.virt-manager.enable = true;

  # Add user to libvirtd group
  users.groups.libvirtd.members = [ vars.primaryUser ];

  # USB passthrough via SPICE
  # Allows passing USB devices to VM through virt-manager.
  virtualisation.spiceUSBRedirection.enable = true;

  # ===========================================================================
  # Shared Memory Files
  # ===========================================================================
  # Create shared memory files for Looking Glass and Scream audio.

  systemd.tmpfiles.rules = [
    # Scream audio shared memory (2MB is enough for audio buffer)
    # The VM writes audio here, scream client reads it.
    "f /dev/shm/scream 0660 ${vars.primaryUser} kvm -"

    # Looking Glass shared memory
    # The VM writes frames here, looking-glass client reads them.
    # Size MUST match kvmfr static_size_mb (256MB = 268435456 bytes)
    # Using truncate format: f+ path mode user group age size
    "f /dev/shm/looking-glass 0660 ${vars.primaryUser} kvm -"

    # Libvirt hooks directory
    "d /var/lib/libvirt/hooks 0755 root root -"
  ];

  # ===========================================================================
  # CPU Pinning Hook
  # ===========================================================================
  # Dynamically restricts host processes to specific cores when VM starts.
  #
  # When VM starts:
  #   Host processes → Cores 0-3, 8-11 only
  #   VM gets exclusive access to cores 4-7, 12-15
  #
  # When VM stops:
  #   Host processes → All cores again
  #
  # This prevents host from interfering with VM's pinned cores.

  environment.etc."libvirt/hooks/qemu" = {
    mode = "0755";
    text = ''
      #!/bin/bash
      set -euo pipefail

      VM_NAME="$1"
      VM_ACTION="$2/$3"

      # VMs that should trigger CPU pinning (from vars.nix)
      CPU_PIN_VMS=(${lib.concatMapStringsSep " " (vm: ''"${vm}"'') vars.cpuPinning.vms})

      # Check if this VM should get CPU pinning
      should_pin=false
      for vm in "''${CPU_PIN_VMS[@]}"; do
        [[ "$VM_NAME" == "$vm" ]] && should_pin=true && break
      done
      [[ "$should_pin" == "false" ]] && exit 0

      # Core assignments from vars.nix
      HOST_CORES="${vars.cpuPinning.hostCores}"  # Cores for host when VM running
      ALL_CORES="${vars.cpuPinning.allCores}"    # All cores (when VM stopped)

      case "$VM_ACTION" in
        prepare/begin)
          # VM starting - restrict host to subset of cores
          systemctl set-property --runtime -- user.slice AllowedCPUs=$HOST_CORES
          systemctl set-property --runtime -- system.slice AllowedCPUs=$HOST_CORES
          systemctl set-property --runtime -- init.scope AllowedCPUs=$HOST_CORES
          ;;
        release/end)
          # VM stopping - give host all cores back
          systemctl set-property --runtime -- user.slice AllowedCPUs=$ALL_CORES
          systemctl set-property --runtime -- system.slice AllowedCPUs=$ALL_CORES
          systemctl set-property --runtime -- init.scope AllowedCPUs=$ALL_CORES
          ;;
      esac
    '';
  };

  # ===========================================================================
  # evdev Input Passthrough
  # ===========================================================================
  # Creates stable symlinks for keyboard/mouse passthrough.
  #
  # Problem: /dev/input/eventX numbers can change between boots.
  # Solution: Create /dev/input/vm-keyboard and /dev/input/vm-mouse symlinks.
  #
  # In your VM XML, reference these stable paths instead of eventX.
  # The VM can then grab your keyboard/mouse for input.
  # Use Scroll Lock (or configured key) to switch input between host/VM.

  systemd.services.evdev-symlinks = {
    description = "Create evdev symlinks for VM input passthrough";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "evdev-link" ''
        #!/bin/bash

        # Keyboards to check (priority order, from vars.nix)
        keyboards=(${lib.concatMapStringsSep " " (k: ''"${k}"'') vars.evdev.keyboards})

        # Mice to check (priority order, from vars.nix)
        mice=(${lib.concatMapStringsSep " " (m: ''"${m}"'') vars.evdev.mice})

        # Find first available keyboard
        for kb in "''${keyboards[@]}"; do
          if [[ -e "/dev/input/by-id/$kb" ]]; then
            ln -sf "by-id/$kb" /dev/input/vm-keyboard
            echo "Keyboard: $kb -> /dev/input/vm-keyboard"
            break
          fi
        done

        [[ -e /dev/input/vm-keyboard ]] || echo "Warning: No keyboard found"

        # Find first available mouse
        for mouse in "''${mice[@]}"; do
          if [[ -e "/dev/input/by-id/$mouse" ]]; then
            ln -sf "by-id/$mouse" /dev/input/vm-mouse
            echo "Mouse: $mouse -> /dev/input/vm-mouse"
            break
          fi
        done

        [[ -e /dev/input/vm-mouse ]] || echo "Warning: No mouse found"
      '';
    };
  };

  # ===========================================================================
  # udev Rules
  # ===========================================================================

  services.udev.extraRules =
    # Trigger evdev symlink service when input devices appear
    ''
      SUBSYSTEM=="input", KERNEL=="event*", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}="evdev-symlinks.service"
    '' +
    # VFIO device permissions
    # Allows your user to access VFIO devices without root.
    ''
      SUBSYSTEM=="vfio", OWNER="root", GROUP="kvm", MODE="0660"
    '' +
    # USB passthrough permissions
    # Devices from these vendors can be passed to VMs.
    # Configured in vars.nix: vars.usb.passthroughVendors
    ''
      ${lib.concatMapStringsSep "\n" (vendor: ''SUBSYSTEM=="usb", ATTR{idVendor}=="${vendor}", MODE="0666"'') vars.usb.passthroughVendors}
    '';

  # ===========================================================================
  # Scream Audio
  # ===========================================================================
  # Low-latency audio from VM via shared memory.
  #
  # In the VM: Install Scream (virtual sound card)
  # On host: scream client reads from /dev/shm/scream
  #
  # Latency: ~5ms (vs ~200ms with network audio)
  # Quality: Bit-perfect audio passthrough

  systemd.user.services.scream = {
    description = "Scream IVSHMEM audio receiver";
    wantedBy = [ "graphical-session.target" ];
    after = [ "pipewire.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.scream}/bin/scream -m /dev/shm/scream -o pipewire";
      Restart = "on-failure";
      RestartSec = "5";
    };
  };

  # ===========================================================================
  # Packages
  # ===========================================================================

  environment.systemPackages = with pkgs; [
    # Looking Glass client
    # Displays VM screen via shared memory.
    # Run: looking-glass-client
    looking-glass-client

    # Scream audio receiver
    # Receives audio from VM.
    # Usually runs as systemd service (above), but CLI available.
    scream
  ];

  # ===========================================================================
  # GPU Driver Configuration - VFIO Mode (Default)
  # ===========================================================================
  # In VFIO mode, AMD is the only display GPU.
  # NVIDIA is bound to vfio-pci for passthrough.

  services.xserver.videoDrivers = [ "amdgpu" ];

  # Disable NVIDIA PRIME (multi-GPU) features
  # Not applicable when NVIDIA is passed through.
  hardware.nvidia.prime.offload.enable = false;
  hardware.nvidia.prime.sync.enable = false;

  # ===========================================================================
  # Normal Mode Specialisation
  # ===========================================================================
  # Alternative boot configuration with NVIDIA on host.
  # Select "Normal" at boot menu to use this configuration.
  #
  # Use cases:
  # - CUDA development
  # - Docker GPU workloads
  # - Native Linux gaming on NVIDIA
  # - Testing NVIDIA driver

  specialisation."Normal".configuration = {
    system.nixos.tags = [ "nvidia-host" ];
    system.nixos.label = lib.mkForce "Normal";

    # -------------------------------------------------------------------------
    # Kernel Parameters - Normal Mode
    # -------------------------------------------------------------------------
    # Remove VFIO binding and CPU isolation.
    # Keep IOMMU enabled (doesn't hurt, and VMs still work).
    boot.kernelParams = lib.mkForce [
      "quiet"
      "splash"
      "rd.udev.log_level=3"
      "boot.shell_on_fail"
      "rd.systemd.show_status=auto"
      "amd_iommu=on"           # Keep IOMMU available
      "iommu=pt"               # Passthrough mode
      "mem_encrypt=on"         # AMD memory encryption
      "amdgpu.dc=1"            # AMD Display Core
      "amdgpu.dcdebugmask=0x10"
    ];

    # -------------------------------------------------------------------------
    # Kernel Modules - Normal Mode
    # -------------------------------------------------------------------------
    # Load amdgpu in initrd for display.
    # VFIO modules still available (for VMs that don't need GPU).
    boot.initrd.kernelModules = lib.mkForce [ "amdgpu" ];
    boot.kernelModules = lib.mkForce [
      "kvm-amd"
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];

    # Only blacklist nouveau (not nvidia)
    boot.blacklistedKernelModules = lib.mkForce [ "nouveau" ];

    # -------------------------------------------------------------------------
    # NVIDIA Driver - Normal Mode
    # -------------------------------------------------------------------------
    services.xserver.videoDrivers = lib.mkForce [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;  # Required for Wayland
      open = true;                # Open source kernel modules (RTX 20xx+)
      nvidiaSettings = true;      # nvidia-settings GUI
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };

    # Docker GPU support
    # Allows: docker run --gpus all nvidia/cuda:...
    hardware.nvidia-container-toolkit.enable = lib.mkForce true;
  };
}
