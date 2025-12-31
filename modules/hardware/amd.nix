# AMD CPU and GPU configuration
{ config, lib, pkgs, inputs, ... }:

{
  options.modules.hardware.amd = {
    enable = lib.mkEnableOption "AMD CPU and GPU support";

    cpu = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.modules.hardware.amd.enable;
        description = "Enable AMD CPU optimizations";
      };

      enableSME = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable AMD Secure Memory Encryption";
      };

      enablePstate = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable AMD P-State driver for better power management";
      };
    };

    gpu = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.modules.hardware.amd.enable;
        description = "Enable AMD GPU support";
      };

      earlyModesetting = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Load amdgpu in initrd for early KMS";
      };

      enableOpenCL = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable OpenCL support for GPU compute";
      };

      enableLact = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable LACT (Linux AMDGPU Controller) for fan curves and overclocking";
      };

      enableMonitoringTools = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install GPU monitoring tools (radeontop, nvtop, corectrl)";
      };

      advancedKernelParams = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable advanced kernel parameters for power management and recovery";
      };
    };

    useNixosHardware = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use nixos-hardware modules for AMD hardware";
    };
  };

  config = lib.mkMerge [
    # Import nixos-hardware modules
    (lib.mkIf (config.modules.hardware.amd.enable && config.modules.hardware.amd.useNixosHardware) {
      imports = [
        inputs.nixos-hardware.nixosModules.common-cpu-amd
        inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
        inputs.nixos-hardware.nixosModules.common-pc-ssd
      ];
    })

    # CPU configuration
    (lib.mkIf config.modules.hardware.amd.cpu.enable {
      boot.kernelModules = [ "kvm-amd" ];

      boot.kernelParams = lib.mkMerge [
        (lib.mkIf config.modules.hardware.amd.cpu.enableSME [ "mem_encrypt=on" ])
        (lib.mkIf config.modules.hardware.amd.cpu.enablePstate [ "amd_pstate=active" ])
      ];

      # AMD microcode updates
      hardware.cpu.amd.updateMicrocode = true;
    })

    # GPU configuration
    (lib.mkIf config.modules.hardware.amd.gpu.enable {
      # Firmware
      hardware.enableRedistributableFirmware = true;
      hardware.enableAllFirmware = true;

      # Early KMS for smooth boot
      boot.initrd.kernelModules = lib.mkIf config.modules.hardware.amd.gpu.earlyModesetting [ "amdgpu" ];

      # AMDGPU kernel parameters
      boot.kernelParams = lib.mkMerge [
        # Basic parameters
        [
          "amdgpu.dc=1"              # Display Core (required for modern displays)
          "amdgpu.dcdebugmask=0x10"  # EDID workarounds
        ]
        # Advanced parameters
        (lib.mkIf config.modules.hardware.amd.gpu.advancedKernelParams [
          "amdgpu.ppfeaturemask=0xffffffff"  # Enable ALL power management features
          "amdgpu.gpu_recovery=1"            # Auto GPU recovery after hangs
          "amdgpu.lockup_timeout=30000"      # Increase timeout before declaring GPU hung
          "amdgpu.gttsize=8192"              # GTT size for system RAM mapping
        ])
      ];

      # Hardware acceleration
      hardware.graphics = {
        enable = true;
        enable32Bit = true;

        extraPackages = with pkgs; [
          libvdpau-va-gl       # VDPAU using VA-API backend
          libva-vdpau-driver   # VA-API using VDPAU backend
          libva-utils          # vainfo tool
        ];

        extraPackages32 = with pkgs.driversi686Linux; [
          libvdpau-va-gl
          libva-vdpau-driver
        ];
      };

      # AMDGPU initrd support
      hardware.amdgpu.initrd.enable = config.modules.hardware.amd.gpu.earlyModesetting;

      # OpenCL support
      hardware.amdgpu.opencl.enable = config.modules.hardware.amd.gpu.enableOpenCL;

      # VA-API driver
      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "radeonsi";
      };

      # LACT - GPU control GUI
      services.lact.enable = config.modules.hardware.amd.gpu.enableLact;

      # Monitoring and control tools
      environment.systemPackages = lib.mkIf config.modules.hardware.amd.gpu.enableMonitoringTools (with pkgs; [
        # Hardware info
        pciutils      # lspci
        lm_sensors    # sensors

        # GPU monitoring
        nvtopPackages.full  # GPU monitor (supports AMD+NVIDIA)
        radeontop           # AMD-specific GPU monitor

        # Graphics testing
        mesa-demos    # glxinfo, glxgears, vdpauinfo
        vulkan-tools  # vulkaninfo

        # GPU control
        corectrl      # GUI for GPU/CPU control

        # Compute
        clinfo        # OpenCL info
      ]);
    })
  ];
}
