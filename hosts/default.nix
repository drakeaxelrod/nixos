# Host configurations
#
# Each host is built using lib.mkHost with its specific settings.
# Host modules are in hosts/<name>/ subdirectories.
#
{ lib }:

let
  users = import ../users;
in

{
  # Default simple NixOS configuration
  nixos = lib.mkHost {
    hostname = "nixos";
    users = with users; [ draxel ];
  };

  # Gaming + Pentesting workstation with VFIO
  toaster = lib.mkHost {
    hostname = "toaster";
    users = with users; [ draxel ];
  };

  # Penetration testing machine
  honeypot = lib.mkHost {
    hostname = "honeypot";
    users = with users; [ bamse ];
  };

  # Add more hosts:
  # laptop = lib.mkHost {
  #   hostname = "laptop";
  #   users = with users; [ draxel ];
  # };
}
