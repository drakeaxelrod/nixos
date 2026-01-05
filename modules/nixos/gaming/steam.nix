# Steam - Gaming Platform with Proton utilities and optimizations
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.gaming.steam;
in
{
  imports = [ ./common.nix ];

  options.modules.gaming.steam = {
    enable = lib.mkEnableOption "Steam gaming platform";

    remotePlay = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall for Steam Remote Play";
    };

    dedicatedServer = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall for Source Dedicated Server";
    };

    localTransfer = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall for Steam Local Network Game Transfers";
    };

    gamescope = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Gamescope compositor and Steam session";
    };

    gamemode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GameMode performance optimizations";
    };

    mangohud = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MangoHud performance overlay";
    };

    protonTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include ProtonUp-Qt and Protontricks";
    };

    steamHardware = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable udev rules for Steam hardware (Steam Controller, Steam Deck, HTC Vive)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Steam
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = cfg.remotePlay;
      dedicatedServer.openFirewall = cfg.dedicatedServer;
      localNetworkGameTransfers.openFirewall = cfg.localTransfer;
      gamescopeSession.enable = cfg.gamescope;
    };

    # Gamescope
    programs.gamescope = lib.mkIf cfg.gamescope {
      enable = true;
      capSysNice = true;
    };

    # GameMode
    programs.gamemode = lib.mkIf cfg.gamemode {
      enable = true;
      settings = {
        general.renice = 10;
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Optimizations activated'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Optimizations deactivated'";
        };
      };
    };

    users.groups.gamemode = lib.mkIf cfg.gamemode {};

    # Steam hardware udev rules (Steam Controller, Steam Deck, HTC Vive)
    hardware.steam-hardware.enable = cfg.steamHardware;

    # System packages
    environment.systemPackages = with pkgs;
      lib.optionals cfg.mangohud [ mangohud ] ++
      lib.optionals cfg.protonTools [ protonup-qt protontricks ] ++
      [ vulkan-tools mesa-demos ];  # Diagnostic tools
  };
}
