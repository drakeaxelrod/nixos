# Core system modules - essential for any NixOS system
{ ... }:

{
  imports = [
    ./boot      # Bootloader selection (systemd/limine/grub)
    ./nix.nix
    ./locale.nix
    ./users.nix
  ];
}
