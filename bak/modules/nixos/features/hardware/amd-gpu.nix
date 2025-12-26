# =============================================================================
# AMD GPU Configuration
# =============================================================================
#
# This module configures AMD GPUs using the open-source amdgpu driver.
# Works for both primary GPU (VFIO mode) and secondary GPU (Normal mode).
#
# Features enabled:
# - Hardware video acceleration (VA-API/VDPAU)
# - OpenCL compute support
# - GPU monitoring and control tools (LACT, corectrl, radeontop)
# - Full power management (fan curves, clocks, voltages)
#
# Key tools:
# - lact          : GUI for fan curves, power limits, overclocking
# - corectrl      : Alternative GUI (similar to MSI Afterburner)
# - radeontop     : CLI GPU monitoring (like nvidia-smi)
# - clinfo        : Shows OpenCL capabilities
# - vainfo        : Shows VA-API capabilities (from libva-utils)
# - vdpauinfo     : Shows VDPAU capabilities (from mesa-demos)
# - vulkaninfo    : Shows Vulkan capabilities
#
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ===========================================================================
  # Firmware
  # ===========================================================================
  # GPU firmware is required for the amdgpu driver to function.
  # This includes microcode for display, video decode, and compute engines.

  hardware.enableRedistributableFirmware = true;  # Includes AMD firmware
  hardware.enableAllFirmware = true;              # Includes additional firmware

  # ===========================================================================
  # Graphics / OpenGL / Vulkan
  # ===========================================================================

  hardware.graphics = {
    enable = true;       # Enable OpenGL/Vulkan support
    enable32Bit = true;  # 32-bit support for Wine/Steam/older games

    # Hardware video acceleration packages
    # VA-API = Video Acceleration API (used by Firefox, mpv, etc.)
    # VDPAU = Video Decode and Presentation API (used by VLC, mplayer)
    extraPackages = with pkgs; [
      # libvdpau-va-gl: Implements VDPAU using VA-API as backend
      # Useful when app wants VDPAU but you only have VA-API driver
      libvdpau-va-gl

      # libva-vdpau-driver: Implements VA-API using VDPAU as backend
      # Useful when app wants VA-API but you only have VDPAU driver
      libva-vdpau-driver

      # libva-utils: Provides 'vainfo' to check VA-API status
      libva-utils
    ];

    # Same for 32-bit applications
    extraPackages32 = with pkgs.driversi686Linux; [
      libvdpau-va-gl
      libva-vdpau-driver
    ];
  };

  # ===========================================================================
  # Early Module Loading
  # ===========================================================================
  # Load amdgpu driver during initramfs (early boot).
  # Benefits:
  # - Native resolution during boot (no mode switch)
  # - Plymouth splash works properly
  # - Faster time to working display

  hardware.amdgpu.initrd.enable = true;

  # ===========================================================================
  # OpenCL (Compute)
  # ===========================================================================
  # Enables GPU compute via OpenCL (ROCm runtime).
  # Used by: Blender, DaVinci Resolve, hashcat, darktable, GIMP, etc.
  # Check with: clinfo

  hardware.amdgpu.opencl.enable = true;

  # ===========================================================================
  # Kernel Parameters
  # ===========================================================================

  boot.kernelParams = [
    # amdgpu.dc=1
    # Enable Display Core (DC) - AMD's display driver.
    # Required for: HDMI 2.0+, DisplayPort MST, FreeSync, HDR
    # Should always be enabled on modern GPUs (GCN 4+)
    "amdgpu.dc=1"

    # amdgpu.dcdebugmask=0x10
    # Suppresses Panel Self Refresh (PSR) debug messages in dmesg.
    # PSR is a power-saving feature that can spam logs on some monitors.
    "amdgpu.dcdebugmask=0x10"

    # amdgpu.ppfeaturemask=0xffffffff
    # Enables ALL power management features:
    # - Fan curve control (via LACT/corectrl)
    # - Clock/voltage adjustment
    # - Power limit adjustment
    # - Performance level switching
    # Without this, tools like LACT/corectrl have limited functionality.
    "amdgpu.ppfeaturemask=0xffffffff"

    # amdgpu.gpu_recovery=1
    # Enable automatic GPU recovery after hangs.
    # When a ring timeout occurs, the driver will attempt to reset the GPU
    # instead of requiring a full system reboot.
    "amdgpu.gpu_recovery=1"

    # amdgpu.lockup_timeout=10000
    # Increase timeout before declaring GPU hung (ms).
    # Default is ~10000ms. Higher values give GPU more time to respond
    # before triggering a reset. Helps with Looking Glass which can cause
    # temporary stalls during high frame capture rates.
    "amdgpu.lockup_timeout=30000"

    # amdgpu.gttsize=8192
    # Graphics Translation Table size in MB.
    # Controls amount of system RAM that can be mapped for GPU use.
    # Larger values help when sharing buffers (Looking Glass KVMFR).
    # Default is usually 256MB or auto-calculated.
    "amdgpu.gttsize=8192"
  ];

  # ===========================================================================
  # LACT - Linux AMDGPU Controller
  # ===========================================================================
  # GUI application for controlling AMD GPUs.
  # Features:
  # - Fan curve editor (custom fan speeds based on temperature)
  # - Power limit adjustment
  # - Clock speed limits (min/max)
  # - Voltage offset (undervolting)
  # - Performance level switching
  # - Real-time monitoring
  #
  # Run with: lact gui
  # Or use the system tray icon

  services.lact.enable = true;

  # ===========================================================================
  # System Packages
  # ===========================================================================

  environment.systemPackages = with pkgs; [
    # --- Hardware Info ---
    dmidecode     # System/BIOS info (sudo dmidecode)
    pciutils      # lspci - list PCI devices
    usbutils      # lsusb - list USB devices
    lm_sensors    # sensors - CPU/GPU temperatures

    # --- GPU Monitoring ---
    nvtopPackages.full  # htop-like GPU monitor (works with AMD+NVIDIA)
    radeontop           # AMD-specific GPU monitor (like nvidia-smi)
                        # Shows GPU/VRAM usage, clocks, etc.

    # --- Graphics Testing ---
    mesa-demos    # glxinfo, glxgears, vdpauinfo
    vulkan-tools  # vulkaninfo - Vulkan capabilities

    # --- GPU Control ---
    corectrl      # GUI for GPU/CPU control (alternative to LACT)
                  # More like MSI Afterburner - also handles CPU
                  # Run: corectrl

    # --- Compute ---
    clinfo        # OpenCL info - shows compute capabilities
  ];

  # ===========================================================================
  # Environment Variables
  # ===========================================================================

  environment.sessionVariables = {
    # Tell VA-API to use the radeonsi driver (Mesa's AMD driver).
    # This ensures hardware video decode works in Firefox, mpv, etc.
    # Check with: vainfo
    LIBVA_DRIVER_NAME = "radeonsi";
  };
}
