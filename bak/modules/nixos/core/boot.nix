# Common boot configuration
{ config, pkgs, lib, ... }:

{
  # Systemd-boot (can be overridden per-host)
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 20;
  boot.loader.timeout = lib.mkDefault 10;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Plymouth boot splash
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;
  boot.initrd.systemd.enable = true;
  boot.plymouth = {
    enable = true;
    theme = "bgrt";
  };

  # Common kernel parameters for quiet boot
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "rd.udev.log_level=3"
    "vt.global_cursor_default=0"
    "boot.shell_on_fail"
    "rd.systemd.show_status=auto"
  ];
}
