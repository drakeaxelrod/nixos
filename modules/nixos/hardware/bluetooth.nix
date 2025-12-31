# Bluetooth support
{ config, lib, pkgs, ... }:

let
  # MediaTek MT7925 bluetooth firmware (missing from standard linux-firmware)
  # The MT7925 is a new WiFi 7 + BT 5.4 combo chip used in modern AMD motherboards
  # Firmware source: https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
  mt7925-bt-firmware = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "mt7925-bluetooth-firmware";
    version = "unstable-2025-01-01";

    # Download MT7925 bluetooth firmware directly from linux-firmware git
    src = pkgs.fetchurl {
      url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/mediatek/mt7925/BT_RAM_CODE_MT7925_1_1_hdr.bin";
      sha256 = "11zas7x4bkys80pjks01ix3hvyjhm0gp9nhp314d0yccnqybg4zk";
    };

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/lib/firmware/mediatek/mt7925
      cp ${src} $out/lib/firmware/mediatek/mt7925/BT_RAM_CODE_MT7925_1_1_hdr.bin
    '';

    meta = {
      description = "MediaTek MT7925 Bluetooth firmware";
      license = lib.licenses.unfreeRedistributableFirmware;
      platforms = lib.platforms.linux;
    };
  };
in
{
  options.modules.hardware.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support";

    enableMT7925 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MediaTek MT7925 bluetooth firmware (for modern AMD motherboards with MT7925 WiFi/BT)";
    };
  };

  config = lib.mkIf config.modules.hardware.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;  # Enable experimental features for better compatibility
        };
      };
    };

    # Ensure firmware is available
    hardware.enableRedistributableFirmware = lib.mkDefault true;

    # Add MT7925 bluetooth firmware if enabled
    hardware.firmware = lib.mkIf config.modules.hardware.bluetooth.enableMT7925 [
      mt7925-bt-firmware
    ];

    # Load bluetooth kernel modules
    # btmtk = MediaTek bluetooth driver
    boot.kernelModules = [ "btusb" "btmtk" ];

    # Blueman for GUI management
    services.blueman.enable = true;
  };
}
