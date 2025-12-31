# Printing support (CUPS)
{ config, lib, pkgs, ... }:

{
  options.modules.services.printing = {
    enable = lib.mkEnableOption "CUPS printing support";

    enableNetworkDiscovery = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable network printer autodiscovery via Avahi";
    };

    drivers = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        gutenprint  # Many printers
        hplip       # HP printers
      ];
      description = "Printer drivers to install";
    };
  };

  config = lib.mkIf config.modules.services.printing.enable {
    services.printing = {
      enable = true;
      drivers = config.modules.services.printing.drivers;
    };

    # Autodiscovery of network printers
    services.avahi = lib.mkIf config.modules.services.printing.enableNetworkDiscovery {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };
}
