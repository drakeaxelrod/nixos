# ZMK Studio - keyboard configuration over USB
#
# Provides udev rules and group access for ZMK Studio.
# Use the web app at https://zmk.studio to configure your keyboard.
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.hardware.zmk;
in
{
  options.modules.hardware.zmk = {
    enable = lib.mkEnableOption "ZMK Studio keyboard support";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Users to add to the dialout group for USB serial access";
      example = [ "draxel" ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Add users to dialout group for USB serial access
    users.users = lib.genAttrs cfg.users (user: {
      extraGroups = [ "dialout" ];
    });

    # udev rules for ZMK keyboards (USB serial and HID access)
    services.udev.extraRules = ''
      # ZMK keyboards - allow user access to USB serial (CDC ACM) devices
      SUBSYSTEM=="tty", ATTRS{bInterfaceClass}=="02", MODE="0660", TAG+="uaccess"
      # ZMK keyboards - allow user access to HID devices
      KERNEL=="hidraw*", ATTRS{bInterfaceClass}=="03", MODE="0660", TAG+="uaccess"
    '';

    # AppImage support for ZMK Studio native app
    programs.appimage = {
      enable = true;
      binfmt = true;  # Register binfmt so AppImages run directly
    };

    # nix-ld for dynamic linking (fixes GPU/EGL in AppImages and other non-Nix binaries)
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Graphics/EGL (required for Electron AppImages on Wayland)
        mesa
        libGL
        libdrm
        vulkan-loader
        # Common dependencies for Electron apps
        libx11
        libxcursor
        libxrandr
        libxi
        libxcb
        libxkbcommon
        wayland
        # Audio
        alsa-lib
        pipewire
        # System
        stdenv.cc.cc.lib
        zlib
        glib
        nss
        nspr
        dbus
        atk
        cups
        gtk3
        pango
        cairo
        expat
        systemd
      ];
    };
  };
}
