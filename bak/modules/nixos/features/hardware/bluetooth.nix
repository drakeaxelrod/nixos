# Bluetooth support
{ config, pkgs, lib, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Blueman for GUI management
  services.blueman.enable = true;
}
