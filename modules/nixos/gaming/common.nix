# Common gaming configuration - shared between all gaming modules
# Import this in gaming modules for consistent system-level gaming optimizations
{ config, lib, pkgs, ... }:

{
  # 32-bit graphics libraries (required for most games)
  hardware.graphics.enable = lib.mkDefault true;
  hardware.graphics.enable32Bit = lib.mkDefault true;

  # Increase vm.max_map_count for games that need it (Star Citizen, etc.)
  boot.kernel.sysctl."vm.max_map_count" = lib.mkForce 2147483642;

  # Controller/gamepad udev rules
  services.udev.packages = [ pkgs.game-devices-udev-rules ];
}
