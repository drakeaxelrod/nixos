# VR - Virtual Reality support for NixOS
# Supports SteamVR, Monado, WiVRn, and other OpenXR runtimes
#
# Runtimes:
#   - steamvr: Valve's SteamVR (proprietary, runs via Steam)
#   - monado: Open-source OpenXR runtime (good for standalone/tethered headsets)
#   - wivrn: Wireless VR streaming to standalone headsets (Quest, Pico, etc.)
#   - envision: FOSS VR stack orchestrator
#
# Usage:
#   modules.gaming.vr = {
#     enable = true;
#     runtime = "wivrn";  # or "monado", "steamvr"
#     steamvr.amdgpuPatch = true;  # For AMD GPUs
#   };
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.gaming.vr;
  # WiVRn package - use nixpkgs version with optional CUDA support
  wivrnPkg =
    if cfg.wivrn.cudaSupport
    then pkgs.wivrn.override { cudaSupport = true; }
    else pkgs.wivrn;
in
{
  imports = [ ./common.nix ];

  options.modules.gaming.vr = {
    enable = lib.mkEnableOption "VR (Virtual Reality) support";

    runtime = lib.mkOption {
      type = lib.types.enum [ "steamvr" "monado" "wivrn" "envision" ];
      default = "steamvr";
      description = ''
        Which OpenXR runtime to use as default:
        - steamvr: Valve's SteamVR (requires Steam)
        - monado: Open-source OpenXR runtime
        - wivrn: Wireless streaming to standalone headsets
        - envision: FOSS VR orchestrator
      '';
    };

    # Monado options
    monado = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.runtime == "monado";
        defaultText = lib.literalExpression "config.modules.gaming.vr.runtime == \"monado\"";
        description = "Enable Monado OpenXR runtime";
      };

      steamvrLighthouse = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable SteamVR Lighthouse tracking support";
      };

      handTracking = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable hand tracking (requires compatible hardware)";
      };
    };

    # WiVRn options
    wivrn = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.runtime == "wivrn";
        defaultText = lib.literalExpression "config.modules.gaming.vr.runtime == \"wivrn\"";
        description = "Enable WiVRn wireless VR streaming";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Open firewall for WiVRn";
      };

      autoStart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Auto-start WiVRn service";
      };

      cudaSupport = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable CUDA hardware encoding (NVIDIA GPUs)";
      };
    };

    # Envision options
    envision = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.runtime == "envision";
        defaultText = lib.literalExpression "config.modules.gaming.vr.runtime == \"envision\"";
        description = "Enable Envision VR orchestrator";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Open firewall for Envision";
      };
    };

    # ALVR - Wireless streaming to Quest/Pico headsets
    alvr = {
      enable = lib.mkEnableOption "ALVR wireless VR streaming";

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Open firewall for ALVR (ports 9943-9944 UDP)";
      };
    };

    # SteamVR options
    steamvr = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.runtime == "steamvr";
        defaultText = lib.literalExpression "config.modules.gaming.vr.runtime == \"steamvr\"";
        description = "Enable SteamVR support";
      };

      amdgpuPatch = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Apply kernel patch for AMD GPU high-priority graphics queue.
          Improves SteamVR performance on AMD GPUs.
        '';
      };

      setcapWrapper = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Create setcap wrapper for vrcompositor to allow CAP_SYS_NICE.
          This fixes the "SteamVR setup is incomplete" warning.
          Requires SteamVR to be installed first.
        '';
      };
    };

    # Overlay tools
    wlxOverlay = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install wlx-overlay-s lightweight OpenXR overlay";
    };

    # SideQuest for Quest sideloading
    sidequest = lib.mkOption {
      type = lib.types.bool;
      default = cfg.alvr.enable;
      defaultText = lib.literalExpression "config.modules.gaming.vr.alvr.enable";
      description = "Install SideQuest for Quest sideloading (needed for ALVR)";
    };

    # OpenComposite for OpenVR->OpenXR translation
    openComposite = lib.mkOption {
      type = lib.types.bool;
      default = cfg.runtime != "steamvr";
      defaultText = lib.literalExpression "config.modules.gaming.vr.runtime != \"steamvr\"";
      description = "Install OpenComposite for OpenVR game compatibility on OpenXR runtimes";
    };
  };

  config = lib.mkIf cfg.enable {
    # SteamVR udev rules for HMDs and controllers
    services.udev.extraRules = lib.mkIf cfg.steamvr.enable ''
      # Valve Index HMD
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2101", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2102", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2103", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2104", MODE="0666"
      # Valve Index Controllers
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2300", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2301", MODE="0666"
      # HTC Vive
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0bb4", ATTRS{idProduct}=="2c87", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0bb4", ATTRS{idProduct}=="0306", MODE="0666"
      # HTC Vive Controllers
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2012", MODE="0666"
      # Base Stations
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2000", MODE="0666"
    '';

    # Allow SteamVR to use CAP_SYS_NICE for the compositor
    # This uses setcap via activation script since the binary is in Steam's directory
    system.activationScripts.steamvrCaps = lib.mkIf (cfg.steamvr.enable && cfg.steamvr.setcapWrapper) {
      text = ''
        STEAMVR_PATH="/home/*/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher"
        for launcher in $STEAMVR_PATH; do
          if [ -f "$launcher" ]; then
            ${pkgs.libcap}/bin/setcap cap_sys_nice+ep "$launcher" 2>/dev/null || true
          fi
        done
      '';
      deps = [];
    };

    # Monado OpenXR runtime
    services.monado = lib.mkIf cfg.monado.enable {
      enable = true;
      defaultRuntime = cfg.runtime == "monado";
    };

    # Monado environment configuration
    systemd.user.services.monado.environment = lib.mkIf cfg.monado.enable {
      STEAMVR_LH_ENABLE = lib.mkIf cfg.monado.steamvrLighthouse "1";
      XRT_COMPOSITOR_COMPUTE = "1";
      WMR_HANDTRACKING = if cfg.monado.handTracking then "1" else "0";
    };

    # Git LFS for hand tracking models
    programs.git = lib.mkIf (cfg.monado.enable && cfg.monado.handTracking) {
      enable = true;
      lfs.enable = true;
    };

    # WiVRn wireless VR streaming (using latest from flake)
    services.wivrn = lib.mkIf cfg.wivrn.enable {
      enable = true;
      openFirewall = cfg.wivrn.openFirewall;
      defaultRuntime = cfg.runtime == "wivrn";
      autoStart = cfg.wivrn.autoStart;
      package = wivrnPkg;
    };

    # Envision VR orchestrator
    programs.envision = lib.mkIf cfg.envision.enable {
      enable = true;
      openFirewall = cfg.envision.openFirewall;
    };

    # ALVR - Wireless streaming to Quest/Pico
    programs.alvr = lib.mkIf cfg.alvr.enable {
      enable = true;
      openFirewall = cfg.alvr.openFirewall;
    };

    # Security limits for real-time scheduling (fixes vrcompositor priority errors)
    security.pam.loginLimits = lib.mkIf cfg.steamvr.enable [
      { domain = "@users"; type = "soft"; item = "nice"; value = "-20"; }
      { domain = "@users"; type = "hard"; item = "nice"; value = "-20"; }
      { domain = "@users"; type = "soft"; item = "rtprio"; value = "99"; }
      { domain = "@users"; type = "hard"; item = "rtprio"; value = "99"; }
    ];

    # AMD GPU kernel patch for SteamVR performance
    boot.kernelPatches = lib.mkIf cfg.steamvr.amdgpuPatch [
      {
        name = "amdgpu-ignore-ctx-privileges";
        patch = pkgs.fetchpatch {
          name = "cap_sys_nice_begone.patch";
          url = "https://github.com/Frogging-Family/community-patches/raw/master/linux61-tkg/cap_sys_nice_begone.mypatch";
          hash = "sha256-Y3a0+x2xvHsfLax/uwycdJf3xLxvVfkfDVqjkxNaYEo=";
        };
      }
    ];

    # System packages
    environment.systemPackages = with pkgs;
      # OpenComposite for OpenVR compatibility
      lib.optionals cfg.openComposite [ opencomposite ] ++
      # wlx-overlay-s
      lib.optionals cfg.wlxOverlay [ wlx-overlay-s ] ++
      # Monado tools
      lib.optionals cfg.monado.enable [ monado ] ++
      # SideQuest for Quest sideloading
      lib.optionals cfg.sidequest [ sidequest ] ++
      # Common VR utilities
      [ ];
  };
}
