# Intel CPU and GPU configuration
{ config, lib, pkgs, inputs, ... }:

{
  # Always import nixos-hardware Intel modules (they're harmless if Intel hardware isn't present)
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  options.modules.hardware.intel = {
    enable = lib.mkEnableOption "Intel CPU and GPU support";

    cpu = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.modules.hardware.intel.enable;
        description = "Enable Intel CPU optimizations";
      };

      enableHWP = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Intel Hardware P-States (HWP) for better power management";
      };

      enableTurboBoost = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Intel Turbo Boost";
      };
    };

    gpu = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.modules.hardware.intel.enable;
        description = "Enable Intel GPU support";
      };

      earlyModesetting = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Load i915 in initrd for early KMS";
      };

      enableGuC = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable GuC (Graphics microController) firmware loading";
      };

      enableHuC = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable HuC (HEVC/H.265 microController) firmware loading";
      };

      enableMonitoringTools = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install GPU monitoring tools (intel_gpu_top, nvtop)";
      };
    };
  };

  config = lib.mkMerge [
    # CPU configuration
    (lib.mkIf config.modules.hardware.intel.cpu.enable {
      boot.kernelModules = [ "kvm-intel" ];

      boot.kernelParams = lib.mkMerge [
        # Hardware P-States (recommended for 6th gen Core and newer)
        (lib.mkIf config.modules.hardware.intel.cpu.enableHWP [ "intel_pstate=active" ])
        # Disable Turbo Boost if needed (for thermals/power saving)
        (lib.mkIf (!config.modules.hardware.intel.cpu.enableTurboBoost) [ "intel_pstate=no_hwp" "intel_pstate.no_turbo=1" ])
      ];

      # Intel microcode updates
      hardware.cpu.intel.updateMicrocode = true;
    })

    # GPU configuration
    (lib.mkIf config.modules.hardware.intel.gpu.enable {
      # Firmware
      hardware.enableRedistributableFirmware = true;
      hardware.enableAllFirmware = true;

      # Early KMS for smooth boot
      boot.initrd.kernelModules = lib.mkIf config.modules.hardware.intel.gpu.earlyModesetting [ "i915" ];

      # i915 kernel parameters
      boot.kernelParams = lib.mkMerge [
        # Enable GuC/HuC firmware loading (required for modern media encode/decode)
        (lib.mkIf (config.modules.hardware.intel.gpu.enableGuC || config.modules.hardware.intel.gpu.enableHuC) [
          "i915.enable_guc=${
            if config.modules.hardware.intel.gpu.enableGuC && config.modules.hardware.intel.gpu.enableHuC then "3"  # GuC + HuC
            else if config.modules.hardware.intel.gpu.enableGuC then "2"  # GuC only
            else if config.modules.hardware.intel.gpu.enableHuC then "1"  # HuC only
            else "0"  # Disabled
          }"
        ])
        # Enable fastboot for faster resume from suspend
        [ "i915.fastboot=1" ]
      ];

      # Hardware acceleration
      hardware.graphics = {
        enable = true;
        enable32Bit = true;

        extraPackages = with pkgs; [
          intel-media-driver  # iHD - for Broadwell (Gen 8) and newer
          intel-vaapi-driver  # i965 - for older GPUs (Ivy Bridge through Skylake)
          libvdpau-va-gl      # VDPAU using VA-API backend
          libva-utils         # vainfo tool
          mesa                # Software fallbacks
        ];

        extraPackages32 = with pkgs.driversi686Linux; [
          intel-media-driver
          intel-vaapi-driver
          libvdpau-va-gl
        ];
      };

      # VA-API driver (iHD for newer, i965 for older Intel GPUs)
      # Can be overridden by NVIDIA module in hybrid systems
      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = lib.mkDefault "iHD";  # Use iHD (newer) by default, fallback to i965 if needed
      };

      # Monitoring and control tools
      environment.systemPackages = lib.mkIf config.modules.hardware.intel.gpu.enableMonitoringTools (with pkgs; [
        # Hardware info
        pciutils      # lspci
        lm_sensors    # sensors

        # GPU monitoring
        nvtopPackages.full  # GPU monitor (supports Intel+AMD+NVIDIA)
        intel-gpu-tools     # intel_gpu_top and other Intel GPU utilities

        # Graphics testing
        mesa-demos    # glxinfo, glxgears, vdpauinfo
        vulkan-tools  # vulkaninfo
      ]);
    })
  ];
}
