# =============================================================================
# NVIDIA GPU Configuration (Standalone / Non-VFIO)
# =============================================================================
#
# This module configures NVIDIA GPUs using the proprietary nvidia driver.
# Use this when NVIDIA is your PRIMARY display GPU (no passthrough).
#
# For VFIO/passthrough setups, use the vfio.nix module instead - it handles
# the NVIDIA driver in its "Normal" specialisation.
#
# Features enabled:
# - Wayland support via modesetting
# - Hardware video acceleration (NVDEC/NVENC via nvidia-vaapi-driver)
# - CUDA support (automatic with driver)
# - Docker GPU support (nvidia-container-toolkit)
#
# Key tools:
# - nvidia-smi        : GPU monitoring and management
# - nvidia-settings   : GUI for driver configuration
# - nvtop             : htop-like GPU monitor
#
# Driver options:
# - stable  : Production driver, most compatible
# - latest  : Newest features, may have bugs
# - beta    : Bleeding edge
# - open    : Open source kernel modules (Turing+, less stable)
#
# =============================================================================

{ config, pkgs, lib, ... }:

let
  # Choose your driver version here
  # Options: stable, latest, beta, production, vulkan_beta
  nvidiaDriver = config.boot.kernelPackages.nvidiaPackages.stable;
in
{
  # ===========================================================================
  # X Server / Display Driver
  # ===========================================================================
  # Tell Xorg/Wayland to use the nvidia driver.
  # This loads the proprietary driver instead of nouveau.

  services.xserver.videoDrivers = [ "nvidia" ];

  # ===========================================================================
  # Kernel Parameters
  # ===========================================================================

  boot.kernelParams = [
    # nvidia-drm.modeset=1
    # Enable kernel modesetting (KMS) for the NVIDIA driver.
    # REQUIRED for Wayland and smooth VT switching.
    # Without this: Wayland won't work, console will be low-res.
    "nvidia-drm.modeset=1"

    # nvidia_drm.fbdev=1
    # Enable framebuffer device for NVIDIA DRM.
    # Provides /dev/fb0 for console and Plymouth.
    # Without this: No native resolution console, no Plymouth splash.
    "nvidia_drm.fbdev=1"

    # nvidia.NVreg_PreserveVideoMemoryAllocations=1
    # Preserve VRAM contents across suspend/resume.
    # REQUIRED for suspend to work properly.
    # Without this: Screen corruption or crash after resume.
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  # ===========================================================================
  # Environment Variables
  # ===========================================================================

  environment.variables = {
    # LIBVA_DRIVER_NAME=nvidia
    # Tell VA-API to use NVIDIA's NVDEC for hardware video decode.
    # Requires nvidia-vaapi-driver package (added below).
    LIBVA_DRIVER_NAME = "nvidia";

    # NVD_BACKEND=direct
    # Use direct rendering for nvidia-vaapi-driver.
    # Alternative: "egl" (may work better in some cases)
    NVD_BACKEND = "direct";

    # These can help with some apps but may break others:
    # GBM_BACKEND = "nvidia-drm";           # Force GBM to use NVIDIA
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # Force GLX to use NVIDIA
  };

  # ===========================================================================
  # License
  # ===========================================================================
  # The NVIDIA driver requires accepting their license.

  nixpkgs.config.nvidia.acceptLicense = true;

  # ===========================================================================
  # NVIDIA Hardware Configuration
  # ===========================================================================

  hardware = {
    nvidia = {
      # -------------------------------------------------------------------------
      # Modesetting
      # -------------------------------------------------------------------------
      # Enable modesetting for Wayland support.
      # This is separate from the kernel parameter - both are needed.
      modesetting.enable = true;

      # -------------------------------------------------------------------------
      # Power Management
      # -------------------------------------------------------------------------
      # Enable systemd-based power management.
      # Helps with suspend/resume but can cause issues on some systems.
      # If you have suspend problems, try disabling this.
      powerManagement.enable = false;

      # Fine-grained power management (Turing+).
      # Allows GPU to fully power down when idle.
      # Can cause issues with some applications - disable if unstable.
      powerManagement.finegrained = false;

      # -------------------------------------------------------------------------
      # Open Source Kernel Modules
      # -------------------------------------------------------------------------
      # Use NVIDIA's open-source kernel modules (nvidia-open).
      # - Only works on Turing (RTX 20xx) and newer
      # - Currently less stable than proprietary modules
      # - May have better Wayland support in future
      # Set to true if you want to try it on RTX 20xx+
      open = false;

      # -------------------------------------------------------------------------
      # NVIDIA Settings
      # -------------------------------------------------------------------------
      # Install nvidia-settings GUI application.
      # Provides: display configuration, GPU info, fan control (limited)
      nvidiaSettings = true;

      # -------------------------------------------------------------------------
      # Driver Package
      # -------------------------------------------------------------------------
      # Which driver version to use (defined in let block above).
      package = nvidiaDriver;
    };

    # ===========================================================================
    # Graphics / OpenGL / Vulkan
    # ===========================================================================

    graphics = {
      enable = true;       # Enable OpenGL support
      enable32Bit = true;  # 32-bit support for Wine/Steam/older games

      # Hardware video acceleration packages
      extraPackages = with pkgs; [
        # nvidia-vaapi-driver: VA-API frontend for NVDEC
        # Allows Firefox, mpv, etc. to use NVIDIA hardware video decode.
        # Check with: vainfo
        nvidia-vaapi-driver

        # libva-vdpau-driver: VA-API backend using VDPAU
        # Fallback for apps that need VA-API
        libva-vdpau-driver

        # libvdpau-va-gl: VDPAU backend using VA-API
        # For apps that want VDPAU
        libvdpau-va-gl

        # mesa: Provides software fallbacks and GLX
        mesa

        # egl-wayland: EGLStream-based Wayland support
        # Required for some Wayland compositors with NVIDIA
        egl-wayland
      ];
    };
  };
}
