# probe-rs - Debug probe support for embedded development
#
# Provides udev rules for J-Link, ST-Link, CMSIS-DAP, and other
# debug probes used with probe-rs and the DWM3001CDK board.
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.hardware.probe-rs;
in
{
  options.modules.hardware.probe-rs = {
    enable = lib.mkEnableOption "probe-rs debug probe support";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Users to grant access to debug probes";
      example = [ "draxel" ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Add users to plugdev group
    users.groups.plugdev = {};
    users.users = lib.genAttrs cfg.users (user: {
      extraGroups = [ "plugdev" "dialout" ];
    });

    # udev rules for debug probes
    services.udev.extraRules = ''
      # J-Link debug probes (SEGGER) — used on DWM3001CDK
      SUBSYSTEM=="usb", ATTR{idVendor}=="1366", MODE="0666", TAG+="uaccess"

      # ST-Link debug probes
      SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="3748", MODE="0666", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="374b", MODE="0666", TAG+="uaccess"

      # CMSIS-DAP probes
      SUBSYSTEM=="usb", ATTR{idVendor}=="0d28", MODE="0666", TAG+="uaccess"

      # nRF52833 native USB (AutoLock firmware VID:PID 1209:0001)
      SUBSYSTEM=="usb", ATTR{idVendor}=="1209", ATTR{idProduct}=="0001", MODE="0666", TAG+="uaccess"
      SUBSYSTEM=="tty", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="0001", MODE="0666", TAG+="uaccess"
    '';
  };
}
