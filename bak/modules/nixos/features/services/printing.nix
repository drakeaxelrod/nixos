# Printing support (CUPS)
{ config, pkgs, lib, ... }:

{
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint        # Many printers
      hplip             # HP printers
    ];
  };

  # Autodiscovery of network printers
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
