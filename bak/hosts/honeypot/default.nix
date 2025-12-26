# NixOS configuration for honeypot - penetration testing machine
#
# Dedicated machine for security research and penetration testing

{ config, pkgs, lib, vars, inputs, ... }:

{
  imports = [
    # Disk layout
    ./disko.nix

    # Core modules (always imported)
    ../../modules/nixos/core

    # Feature modules
    ../../modules/nixos/features/desktop/gnome.nix
    ../../modules/nixos/features/hardware/audio.nix
    ../../modules/nixos/features/hardware/bluetooth.nix
    ../../modules/nixos/features/services/ssh.nix
    ../../modules/nixos/features/services/printing.nix
    ../../modules/nixos/features/virtualization/docker.nix
    ../../modules/nixos/features/networking

    # Users on this machine
    ../../users/bamse
  ];

  # ==========================================================================
  # Host Identity
  # ==========================================================================

  networking.hostName = vars.hostname;

  # ==========================================================================
  # Boot Configuration
  # ==========================================================================

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel for best hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ==========================================================================
  # Security (pentest-specific)
  # ==========================================================================

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
  # Networking (pentest-specific)
  # ==========================================================================

  # More permissive firewall for testing
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 8080 8443 4444 5555 ];
    allowedUDPPorts = [ 53 ];
  };

  # Proxychains support
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
  # Home Manager
  # ==========================================================================

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs vars; };
  };

  # ==========================================================================
  # Packages (system-wide pentest tools)
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
  # Virtualization (for running target VMs)
  # ==========================================================================

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };

  # ==========================================================================
  # System State Version
  # ==========================================================================

  system.stateVersion = vars.stateVersion;
}
