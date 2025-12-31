# Bluetooth support
{ config, lib, ... }:

{
  options.modules.hardware.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support";
  };

  config = lib.mkIf config.modules.hardware.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # Blueman for GUI management
    services.blueman.enable = true;
  };
}
