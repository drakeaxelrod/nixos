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

    # OpenComposite for OpenVR->OpenXR translation
    openComposite = lib.mkOption {
      type = lib.types.bool;
      default = cfg.runtime != "steamvr";
      defaultText = lib.literalExpression "config.modules.gaming.vr.runtime != \"steamvr\"";
      description = "Install OpenComposite for OpenVR game compatibility on OpenXR runtimes";
    };
  };

  config = lib.mkIf cfg.enable {
    # SteamVR requirements
    # CAP_SYS_NICE for SteamVR compositor
    security.wrappers = lib.mkIf cfg.steamvr.enable {
      "vrcompositor" = {
        owner = "root";
        group = "root";
        source = "/home/draxel/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher";
        capabilities = "cap_sys_nice+ep";
      };
    };

    # SteamVR udev rules for HMDs
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

    # WiVRn wireless VR streaming
    services.wivrn = lib.mkIf cfg.wivrn.enable {
      enable = true;
      openFirewall = cfg.wivrn.openFirewall;
      defaultRuntime = cfg.runtime == "wivrn";
      autoStart = cfg.wivrn.autoStart;
      package = lib.mkIf cfg.wivrn.cudaSupport (pkgs.wivrn.override { cudaSupport = true; });
    };

    # Envision VR orchestrator
    programs.envision = lib.mkIf cfg.envision.enable {
      enable = true;
      openFirewall = cfg.envision.openFirewall;
    };

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
      # Common VR utilities
      [ ];
  };
}
