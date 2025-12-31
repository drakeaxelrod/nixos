# Honeypot - Penetration Testing Machine
#
# Dedicated machine for security research and penetration testing.
# Includes comprehensive pentesting tools, Metasploit, Wireshark,
# and proper permissions for security testing.

{ config, pkgs, lib, inputs, meta, ... }:

let
  # Helper to get specific users from meta.users
  # Usage: users.bamse or users.all
  users = lib.genAttrs meta.users (name: name) // {
    all = meta.users;
  };
in

{
  imports = [
    ./disko.nix
  ];

  # ==========================================================================
  # System Identity
  # ==========================================================================
  # Derived from mkHost - no need to set here
  # networking.hostName = meta.hostname;      # "honeypot"
  # system.stateVersion = meta.stateVersion;  # "25.11"

  # ==========================================================================
  # Bootloader
  # ==========================================================================

  modules.core.boot = {
    loader = "systemd";
    maxGenerations = 10;
    timeout = 3;
  };

  # Use latest kernel for best hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ==========================================================================
  # Hardware
  # ==========================================================================

  # modules.hardware.amd.enable = true;      # Enable based on hardware
  # modules.hardware.nvidia.enable = true;
  modules.hardware.audio.enable = true;
  modules.hardware.bluetooth.enable = true;

  # ==========================================================================
  # Desktop Environment
  # ==========================================================================

  modules.desktop.gnome.enable = true;
  modules.desktop.wayland.enable = true;

  # ==========================================================================
  # Networking
  # ==========================================================================

  # More permissive firewall for testing
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 8080 8443 4444 5555 ];
    allowedUDPPorts = [ 53 ];
  };

  # ==========================================================================
  # Services
  # ==========================================================================

  modules.services.openssh.enable = true;
  modules.services.printing.enable = true;

  # Metasploit database
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "msf" ];
    ensureUsers = [{
      name = "msf";
      ensureDBOwnership = true;
    }];
  };

  # ==========================================================================
  # Security (pentest-specific)
  # ==========================================================================

  modules.security.base.enable = true;

  # Allow packet capture without root
  programs.wireshark.enable = true;

  # Enable nmap ping scans
  security.wrappers = {
    nmap = {
      source = "${pkgs.nmap}/bin/nmap";
      capabilities = "cap_net_raw+ep";
      owner = "root";
      group = "root";
    };
  };

  # Proxychains configuration
  environment.etc."proxychains.conf".text = ''
    strict_chain
    proxy_dns
    tcp_read_time_out 15000
    tcp_connect_time_out 8000

    [ProxyList]
    # Add your proxies here
    # socks5 127.0.0.1 1080
  '';

  # ==========================================================================
  # Virtualization
  # ==========================================================================

  modules.virtualization.docker = {
    enable = true;
    users = [ users.bamse ];  # Derived from meta.users
  };

  modules.virtualization.libvirt = {
    enable = true;
    users = [ users.bamse ];  # Derived from meta.users
  };

  # ==========================================================================
  # System Packages (pentesting tools)
  # ==========================================================================

  environment.systemPackages = with pkgs; [
    # Core utilities
    git
    wget
    curl
    tree
    ripgrep
    fd
    file
    unzip
    p7zip
    htop
    btop

    # Network tools (system-level)
    nmap
    wireshark
    tcpdump
    netcat-gnu
    socat
    proxychains-ng

    # VPN/Tunneling
    openvpn
    wireguard-tools

    # Virtualization
    virt-manager
    qemu
  ];

  # ==========================================================================
  # Users
  # ==========================================================================
  # Users are defined as self-contained modules in users/ directory
  # and composed in flake.nix via: users = with self.users; [ bamse ];
}
