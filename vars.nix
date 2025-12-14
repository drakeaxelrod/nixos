# Centralized configuration variables
# Edit this file to customize your system
{
  # ==========================================================================
  # System Identity
  # ==========================================================================

  hostname = "toaster";
  stateVersion = "25.11";  # NixOS version - don't change after install

  # ==========================================================================
  # Primary User
  # ==========================================================================

  user = {
    name = "draxel";
    description = "draxel";
    initialPassword = "changeme";  # Change on first login!
    shell = "zsh";  # Options: zsh, bash, fish
    groups = [
      "wheel"
      "networkmanager"
      "libvirtd"
      "docker"
      "input"
      "kvm"
    ];
  };

  # ==========================================================================
  # Localization
  # ==========================================================================

  timezone = "Europe/Stockholm";
  locale = "en_US.UTF-8";
  keymap = "us";

  # ==========================================================================
  # Networking
  # ==========================================================================

  network = {
    # Bridge interface for VMs (direct network access, better than NAT)
    bridge = {
      enable = true;
      name = "br0";
      # Physical interface to bridge (update after install with: ip link)
      # Common: enp6s0 (ethernet), wlp5s0 (wifi - bridging wifi is complex)
      interface = "enp6s0";
    };

    # Trusted interfaces (no firewall restrictions)
    trustedInterfaces = [
      "tailscale0"
      "virbr0"  # libvirt default NAT
      "br0"     # VM bridge
    ];
  };

  # ==========================================================================
  # GPU / VFIO
  # ==========================================================================

  gpu = {
    # NVIDIA GPU PCI IDs for VFIO passthrough
    # Find with: lspci -nn | grep -i nvidia
    # Format: "10de:XXXX" (vendor:device)
    vfioIds = [
      # Uncomment and update after first boot:
      # "10de:2782"  # RTX 5070 Ti GPU
      # "10de:22bc"  # RTX 5070 Ti Audio
    ];
  };

  # ==========================================================================
  # USB Passthrough Devices
  # ==========================================================================

  usb = {
    # Vendor IDs for USB devices that can be passed to VMs
    # Find with: lsusb
    passthroughVendors = [
      "045e"  # Microsoft (Xbox controllers)
      "054c"  # Sony (PlayStation controllers)
      "057e"  # Nintendo (Switch controllers)
      "1050"  # Yubico (YubiKey)
    ];
  };
}
