# Wacom - tablet driver and configuration tools
#
# Enables the xf86-input-wacom driver and optional KDE integration.
# Tablets are auto-detected via libwacom; configure pressure curves,
# button mapping, and display mapping through KDE System Settings.
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.hardware.wacom;
in
{
  options.modules.hardware.wacom = {
    enable = lib.mkEnableOption "Wacom tablet support";
  };

  config = lib.mkIf cfg.enable {
    # Wacom kernel driver + xf86-input-wacom (works under XWayland too)
    services.xserver.wacom.enable = true;

    environment.systemPackages = with pkgs; [
      libwacom        # Tablet device database and detection
      xf86_input_wacom  # CLI tools: xsetwacom, etc.
      wacomtablet     # KDE Plasma tablet settings (kcm_wacomtablet)
    ];
  };
}
