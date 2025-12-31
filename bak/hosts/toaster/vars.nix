# Host-specific variables for toaster
# Gaming + pentesting workstation
# Hardware: AMD Ryzen 7 9800X3D, RTX 5070 Ti, 64GB DDR5, 2x 2TB NVMe RAID 1
{
  # ==========================================================================
  # System Identity
  # ==========================================================================

  system = "x86_64-linux";
  hostname = "toaster";
  stateVersion = "25.11";  # NixOS version - don't change after install

  # ==========================================================================
  # Users on this machine
  # ==========================================================================

  users = [ "draxel" ];  # Users to enable on this host

  # Primary user (for sudo rules, home-manager default, etc.)
  primaryUser = "draxel";

  # ==========================================================================
  # Localization
  # ==========================================================================

  timezone = "Europe/Stockholm";
  locale = "en_US.UTF-8";
  keymap = "us";

  # ==========================================================================
  # Networking (hardware-specific)
  # ==========================================================================

  network = {
    # Trusted interfaces (no firewall restrictions)
    trustedInterfaces = [
      "eno1"
      "br0"
      "virbr0"
      "docker0"
      "tailscale0"
    ];
  };

  # ==========================================================================
  # GPU / VFIO (hardware-specific)
  # ==========================================================================

  gpu = {
    # NVIDIA GPU PCI IDs for VFIO passthrough
    # Find with: lspci -nn | grep -i nvidia
    # Format: "10de:XXXX" (vendor:device)
    vfioIds = [
      # 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GB203 [GeForce RTX 5070 Ti] [10de:2c05] (rev a1)
      "10de:2c05"  # GPU
      # 01:00.1 Audio device [0403]: NVIDIA Corporation GB203 High Definition Audio Controller [10de:22e9] (rev a1)
      "10de:22e9"  # Audio
    ];
  };

  # ==========================================================================
  # CPU Pinning (hardware-specific for 9800X3D)
  # ==========================================================================

  cpuPinning = {
    # VMs that get CPU pinning (restrict host to subset of cores during VM run)
    vms = [ "win11" ];
    # Cores for host when VM is running (9800X3D: 0-7 physical, 8-15 SMT)
    hostCores = "0-3,8-11";
    # All cores (restored when VM stops)
    allCores = "0-15";
  };

  # ==========================================================================
  # USB Passthrough Devices
  # ==========================================================================

  # Input devices for VM passthrough (checked in order, first match wins)
  evdev = {
    keyboards = [
      "usb-ZSA_Technology_Labs_Moonlander_Mark_I_65GKR_EeoXb6-event-kbd"
      "usb-Gaming_KB_Gaming_KB-event-kbd"
      "usb-Ducky_Ducky_One2_Mini_RGB_DK-V1.10-201231-if02-event-kbd"
    ];
    mice = [
      "usb-Logitech_G502_HERO_Gaming_Mouse_166934583338-event-mouse"
      "usb-Logitech_G502_HERO_Gaming_Mouse_015F34533338-event-mouse"
    ];
  };

  usb = {
    # Vendor IDs for USB devices that can be passed to VMs
    # Find with: lsusb
    passthroughVendors = [
      "045e"  # Microsoft (Xbox controllers)
      "054c"  # Sony (PlayStation controllers)
      "057e"  # Nintendo (Switch controllers)
      "1050"  # Yubico (YubiKey)
      "3297"  # ZSA
      "046d"  # Logitech
    ];
  };

  # ==========================================================================
  # Features to enable on this host
  # ==========================================================================

  features = {
    vfio = true;        # GPU passthrough
    docker = true;      # Container runtime
    tailscale = true;   # VPN
    gaming = true;      # Steam, etc.
    nvidia = true;      # NVIDIA GPU (for nixos-hardware modules)
    amdCpu = true;      # AMD CPU (for nixos-hardware modules)
  };
}
