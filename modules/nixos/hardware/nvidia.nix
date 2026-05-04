# NVIDIA GPU configuration
#
# ==============================================================================
# NVIDIA PRIME Hybrid Graphics Support
# ==============================================================================
#
# This module provides NVIDIA GPU support with optional PRIME hybrid graphics
# for laptops/desktops with both integrated GPU (iGPU) and discrete NVIDIA GPU (dGPU).
#
# USAGE EXAMPLES:
#
# 1. Discrete GPU only (no hybrid graphics):
#    modules.hardware.nvidia.enable = true;
#
# 2. Hybrid graphics with on-demand NVIDIA (recommended for power saving):
#    modules.hardware.nvidia = {
#      enable = true;
#      prime = {
#        enable = true;
#        mode = "offload";  # On-demand NVIDIA rendering
#        amdBusId = "PCI:13:0:0";     # AMD iGPU (find with: lspci | grep VGA)
#        nvidiaBusId = "PCI:1:0:0";   # NVIDIA dGPU
#      };
#    };
#
#    Then run apps with: nvidia-offload <application>
#    Example: nvidia-offload steam
#
# 3. Hybrid graphics with always-on NVIDIA (maximum performance):
#    Same as above but set mode = "sync";
#
# PRIME MODES:
#   - "offload": iGPU is primary, use NVIDIA on-demand with nvidia-offload command
#                Best for: Battery life, power saving, general desktop use
#   - "sync":    Always use NVIDIA for all rendering (iGPU disabled)
#                Best for: Maximum performance, desktop systems with AC power
#   - "reverse-sync": NVIDIA renders, outputs through iGPU (experimental)
#                Best for: External displays, specific hybrid setups
#
# FINDING PCI BUS IDs:
#   Run: lspci | grep -E "VGA|3D"
#   Example output:
#     01:00.0 VGA compatible controller: NVIDIA Corporation ...
#     0d:00.0 VGA compatible controller: Advanced Micro Devices ...
#   Convert to PCI Bus ID format:
#     01:00.0 → PCI:1:0:0   (remove leading zeros)
#     0d:00.0 → PCI:13:0:0  (0d hex = 13 decimal)
#
# ==============================================================================

{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.hardware.nvidia;
in
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
      description = "Use open-source NVIDIA kernel modules (REQUIRED for RTX 50-series, optional for RTX 20xx+)";
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

      # Fix black screen after suspend (affects multiple NVIDIA GPU generations)
      # See: https://discourse.nixos.org/t/black-screen-after-suspend-hibernate-with-nvidia/54341
      systemd.services."systemd-suspend".serviceConfig.Environment = ''SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=false'';

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
    (lib.mkIf (cfg.enable && cfg.prime.enable) {
      hardware.nvidia.prime = lib.mkMerge [
        # Common settings
        {
          nvidiaBusId = cfg.prime.nvidiaBusId;
        }

        # Sync mode (always use NVIDIA)
        (lib.mkIf (cfg.prime.mode == "sync") {
          sync.enable = true;
        })

        # Offload mode (use NVIDIA on-demand)
        (lib.mkIf (cfg.prime.mode == "offload") {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
        })

        # Reverse sync mode (NVIDIA as primary, render on iGPU)
        (lib.mkIf (cfg.prime.mode == "reverse-sync") {
          reverseSync.enable = true;
        })

        # Intel iGPU
        (lib.mkIf (cfg.prime.intelBusId != "") {
          intelBusId = cfg.prime.intelBusId;
        })

        # AMD iGPU
        (lib.mkIf (cfg.prime.amdBusId != "") {
          amdgpuBusId = cfg.prime.amdBusId;
        })
      ];
    })

    # In PRIME offload mode, the NVIDIA GPU (often card0) has no display outputs
    # for the built-in panel, but HDMI/DP ports are wired through it.
    # KWin's default device enumeration order may try the dGPU first and fail.
    # KWIN_DRM_DEVICES sets explicit order: iGPU first (primary/eDP), dGPU second (HDMI/DP).
    # Note: KWIN_DRM_DEVICES splits on ':', so by-path symlinks (which contain colons) can't be used.
    # Create stable /dev/dri/igpu and /dev/dri/dgpu symlinks via udev.
    (lib.mkIf (cfg.enable && cfg.prime.enable && cfg.prime.mode == "offload") (
      let
        # Convert "PCI:0:2:0" to "00:02.0" for udev matching
        busIdToPciSlot = busId:
          let parts = lib.splitString ":" (lib.removePrefix "PCI:" busId);
          in lib.fixedWidthString 2 "0" (builtins.elemAt parts 0)
             + ":" + lib.fixedWidthString 2 "0" (builtins.elemAt parts 1)
             + "." + builtins.elemAt parts 2;

        igpuBusId =
          if cfg.prime.intelBusId != "" then cfg.prime.intelBusId
          else if cfg.prime.amdBusId != "" then cfg.prime.amdBusId
          else null;

        igpuPciSlot = if igpuBusId != null then busIdToPciSlot igpuBusId else null;
        dgpuPciSlot = busIdToPciSlot cfg.prime.nvidiaBusId;
      in lib.mkIf (igpuPciSlot != null) {
        services.udev.extraRules = ''
          SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:${igpuPciSlot}", SYMLINK+="dri/igpu"
          SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:${dgpuPciSlot}", SYMLINK+="dri/dgpu"
        '';
        # iGPU first (primary, drives eDP), dGPU second (HDMI/DP outputs)
        environment.variables.KWIN_DRM_DEVICES = "/dev/dri/igpu:/dev/dri/dgpu";
      }
    ))
  ];
}
