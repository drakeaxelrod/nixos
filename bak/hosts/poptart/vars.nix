# Host-specific variables for poptart
# Barebones developer machine
{
  # ==========================================================================
  # System Identity
  # ==========================================================================

  system = "x86_64-linux";
  hostname = "poptart";
  stateVersion = "25.11";

  # ==========================================================================
  # Users on this machine
  # ==========================================================================

  users = [ "hollywood" ];
  primaryUser = "hollywood";

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
    bridge = {
      enable = false;
      name = "br0";
      interface = "eth0";
    };

    trustedInterfaces = [
      "tailscale0"
    ];
  };

  # ==========================================================================
  # Features
  # ==========================================================================

  features = {
    vfio = false;
    docker = true;
    tailscale = true;
    gaming = false;
    nvidia = false;
    amdCpu = false;  # Set based on actual hardware
  };
}
