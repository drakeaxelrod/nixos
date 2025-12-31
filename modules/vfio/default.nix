# VFIO GPU Passthrough module
#
# Provides GPU isolation for VM passthrough with optional dual-boot support.
# Integrates with virtualisation.vms module for automatic PCI ID derivation.
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.vfio;
in
{
  imports = [
    ./core.nix
    ./looking-glass.nix
    ./scream.nix
  ];

  options.modules.vfio = {
    enable = lib.mkEnableOption "VFIO GPU passthrough";

    primaryMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        When true, GPU is ALWAYS isolated for VM passthrough (VFIO primary mode).
        NVIDIA driver never loads, host uses AMD iGPU exclusively.
        When false, GPU is available on host (for CUDA, gaming, etc.).
      '';
    };

    gpuPciIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "10de:2782" "10de:22bc" ];
      description = ''
        PCI vendor:device IDs for GPU passthrough.
        Find with: lspci -nn | grep -i nvidia
        Format: "vendor:device" (e.g., "10de:2782" for RTX 5070 Ti)
      '';
    };

    gpuPciAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "0000:01:00.0" "0000:01:00.1" ];
      description = ''
        Full PCI addresses for GPU (used in libvirt XML).
        Find with: lspci -D | grep -i nvidia
        Format: "0000:XX:XX.X"
      '';
    };

    usbPassthroughVendors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "045e"  # Microsoft (Xbox controllers)
        "054c"  # Sony (PlayStation controllers)
        "057e"  # Nintendo (Switch controllers)
        "1050"  # Yubico (YubiKey)
      ];
      description = "USB vendor IDs for device passthrough";
    };

    # =========================================================================
    # Dual-Boot Configuration
    # =========================================================================
    dualBoot = {
      enable = lib.mkEnableOption "dual-boot specialisations for GPU modes";

      defaultMode = lib.mkOption {
        type = lib.types.enum [ "host" "vfio" ];
        default = "host";
        description = ''
          Which GPU mode is the default boot entry.
          - "host": Default boots with GPU on host (gaming/CUDA), VFIO in specialisation
          - "vfio": Default boots with GPU isolated (VM), host GPU in specialisation
        '';
      };

      hostLabel = lib.mkOption {
        type = lib.types.str;
        default = "host";
        description = "Boot menu tag for host GPU mode (shows as 'NixOS - host')";
      };

      vfioLabel = lib.mkOption {
        type = lib.types.str;
        default = "vfio";
        description = "Boot menu tag for VFIO mode (shows as 'NixOS - vfio')";
      };
    };
  };

  # ===========================================================================
  # Dual-Boot Specialisation Generation
  # ===========================================================================
  config = lib.mkIf cfg.dualBoot.enable {
    # When defaultMode = "host": VFIO is in specialisation
    # When defaultMode = "vfio": Host GPU is in specialisation
    specialisation = lib.mkMerge [
      # VFIO specialisation (when host GPU is default)
      (lib.mkIf (cfg.dualBoot.defaultMode == "host") {
        "${cfg.dualBoot.vfioLabel}" = {
          inheritParentConfig = true;
          configuration = {
            system.nixos.tags = [ cfg.dualBoot.vfioLabel ];
            modules.vfio = {
              enable = lib.mkForce true;
              primaryMode = lib.mkForce true;
            };
          };
        };
      })

      # Host GPU specialisation (when VFIO is default)
      (lib.mkIf (cfg.dualBoot.defaultMode == "vfio") {
        "${cfg.dualBoot.hostLabel}" = {
          inheritParentConfig = true;
          configuration = {
            system.nixos.tags = [ cfg.dualBoot.hostLabel ];
            modules.vfio = {
              enable = lib.mkForce false;
              primaryMode = lib.mkForce false;
            };
          };
        };
      })
    ];

    # Set default mode based on configuration
    modules.vfio = {
      enable = lib.mkDefault (cfg.dualBoot.defaultMode == "vfio");
      primaryMode = lib.mkDefault (cfg.dualBoot.defaultMode == "vfio");
    };
  };
}
