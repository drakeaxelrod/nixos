# Host-specific variables for honeypot
# Dedicated penetration testing machine
{
  # ==========================================================================
  # System Identity
  # ==========================================================================

  system = "x86_64-linux";
  hostname = "honeypot";
  stateVersion = "25.11";

  # ==========================================================================
  # Users on this machine
  # ==========================================================================

  users = [ "bamse" ];
  primaryUser = "bamse";

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
    nvidia = false;      # No NVIDIA GPU
    amdCpu = false;      # Unknown CPU - set when deploying
  };
}
