# Plymouth boot splash and silent boot
{ config, lib, ... }:

{
  options.modules.system.boot.plymouth = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Plymouth boot splash";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "bgrt";
      description = "Plymouth theme (bgrt shows vendor logo)";
    };

    silentBoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable silent boot (quiet kernel params)";
    };
  };

  config = lib.mkIf config.modules.system.boot.plymouth.enable {
    # Plymouth configuration
    boot.plymouth = {
      enable = true;
      theme = config.modules.system.boot.plymouth.theme;
    };

    # Systemd in initrd for smooth transitions
    boot.initrd.systemd.enable = true;
    boot.initrd.verbose = false;

    # Silent boot kernel parameters
    boot.kernelParams = lib.mkIf config.modules.system.boot.plymouth.silentBoot [
      "quiet"
      "splash"
      "loglevel=3"
      "rd.udev.log_level=3"
      "vt.global_cursor_default=0"
      "boot.shell_on_fail"
      "rd.systemd.show_status=auto"
    ];

    # Console log level
    boot.consoleLogLevel = lib.mkIf config.modules.system.boot.plymouth.silentBoot 0;
  };
}
