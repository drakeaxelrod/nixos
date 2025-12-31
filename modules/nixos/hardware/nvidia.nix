# NVIDIA GPU configuration
{ config, lib, pkgs, inputs, ... }:

{
  options.modules.hardware.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU support";

    prime = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable NVIDIA PRIME for hybrid graphics";
      };

      mode = lib.mkOption {
        type = lib.types.enum [ "sync" "offload" "reverse-sync" ];
        default = "offload";
        description = "PRIME mode: sync (always on), offload (on-demand), or reverse-sync";
      };

      nvidiaBusId = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "PCI:1:0:0";
        description = "PCI Bus ID for NVIDIA GPU (use lspci)";
      };

      intelBusId = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "PCI:0:2:0";
        description = "PCI Bus ID for Intel iGPU (use lspci)";
      };

      amdBusId = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "PCI:6:0:0";
        description = "PCI Bus ID for AMD iGPU (use lspci)";
      };
    };

    openDriver = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use open-source NVIDIA kernel modules (requires RTX 16xx+ / GTX 16xx+)";
    };

    powerManagement = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable NVIDIA power management";
      };

      finegrained = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable fine-grained power management (experimental, requires offload mode)";
      };
    };

    enableWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Wayland support via kernel modesetting";
    };

    enableSuspendSupport = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable proper suspend/resume support";
    };

    useNixosHardware = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use nixos-hardware modules for NVIDIA";
    };
  };

  config = lib.mkMerge [
    # NVIDIA configuration
    (lib.mkIf config.modules.hardware.nvidia.enable {
      # Accept NVIDIA license
      nixpkgs.config.nvidia.acceptLicense = true;

      # Load nvidia driver for Xorg and Wayland
      services.xserver.videoDrivers = [ "nvidia" ];

      # Kernel parameters
      boot.kernelParams = lib.mkMerge [
        # Wayland support
        (lib.mkIf config.modules.hardware.nvidia.enableWayland [
          "nvidia-drm.modeset=1"  # Enable kernel modesetting
          "nvidia_drm.fbdev=1"    # Framebuffer for console/Plymouth
        ])
        # Suspend support
        (lib.mkIf config.modules.hardware.nvidia.enableSuspendSupport [
          "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # Preserve VRAM across suspend
        ])
      ];

      # Environment variables
      environment.variables = {
        # Override AMD in hybrid systems - NVIDIA provides better video decode
        LIBVA_DRIVER_NAME = lib.mkOverride 900 "nvidia";
        NVD_BACKEND = "direct";        # Direct rendering for nvidia-vaapi-driver
      };

      hardware.nvidia = {
        # Use the NVidia open source kernel module (requires RTX 16xx+)
        open = config.modules.hardware.nvidia.openDriver;

        # Modesetting is required for Wayland
        modesetting.enable = config.modules.hardware.nvidia.enableWayland;

        # Power management
        powerManagement = {
          enable = config.modules.hardware.nvidia.powerManagement.enable;
          finegrained = config.modules.hardware.nvidia.powerManagement.finegrained;
        };

        # Use the latest stable driver
        package = config.boot.kernelPackages.nvidiaPackages.stable;

        # NVIDIA settings GUI
        nvidiaSettings = true;
      };

      # Hardware acceleration
      hardware.graphics = {
        enable = true;
        enable32Bit = true;

        extraPackages = with pkgs; [
          nvidia-vaapi-driver  # VA-API frontend for NVDEC
          libva-vdpau-driver   # VA-API using VDPAU backend
          libvdpau-va-gl       # VDPAU using VA-API backend
          mesa                 # Software fallbacks and GLX
          egl-wayland          # EGLStream-based Wayland support
        ];
      };

      # Monitoring tools
      environment.systemPackages = with pkgs; [
        nvtopPackages.full   # GPU monitor
        pciutils             # lspci
        vulkan-tools         # vulkaninfo
      ];
    })

    # NVIDIA PRIME configuration
    (lib.mkIf (config.modules.hardware.nvidia.enable && config.modules.hardware.nvidia.prime.enable) {
      hardware.nvidia.prime = lib.mkMerge [
        # Common settings
        {
          nvidiaBusId = config.modules.hardware.nvidia.prime.nvidiaBusId;
        }

        # Sync mode (always use NVIDIA)
        (lib.mkIf (config.modules.hardware.nvidia.prime.mode == "sync") {
          sync.enable = true;
        })

        # Offload mode (use NVIDIA on-demand)
        (lib.mkIf (config.modules.hardware.nvidia.prime.mode == "offload") {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
        })

        # Reverse sync mode (NVIDIA as primary, render on iGPU)
        (lib.mkIf (config.modules.hardware.nvidia.prime.mode == "reverse-sync") {
          reverseSync.enable = true;
        })

        # Intel iGPU
        (lib.mkIf (config.modules.hardware.nvidia.prime.intelBusId != "") {
          intelBusId = config.modules.hardware.nvidia.prime.intelBusId;
        })

        # AMD iGPU
        (lib.mkIf (config.modules.hardware.nvidia.prime.amdBusId != "") {
          amdgpuBusId = config.modules.hardware.nvidia.prime.amdBusId;
        })
      ];
    })
  ];
}
