# Bluetooth support
# MediaTek MT7925 bluetooth firmware is now included in standard linux-firmware
{ config, lib, pkgs, ... }:

{
  options.modules.hardware.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support";
  };

  config = lib.mkIf config.modules.hardware.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;  # Enable experimental features for better compatibility
          AutoEnable = true;    # Automatically power on the adapter at boot
          DiscoverableTimeout = 0;  # Stay discoverable indefinitely
          PairableTimeout = 0;      # Stay pairable indefinitely
        };
        Policy = {
          AutoEnable = true;
        };
      };
    };

    # Ensure firmware is available (includes MT7925 bluetooth firmware)
    hardware.enableRedistributableFirmware = lib.mkDefault true;

    # Load bluetooth kernel modules
    # btmtk = MediaTek bluetooth driver (for MT7925 and other MediaTek chips)
    boot.kernelModules = [ "btusb" "btmtk" ];

    # Blueman for GUI management (fallback for KDE's bluedevil)
    services.blueman.enable = true;
  };
}
