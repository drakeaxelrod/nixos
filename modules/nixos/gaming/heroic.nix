# Heroic Games Launcher - Epic/GOG games with optimizations
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.gaming.heroic;
in
{
  imports = [ ./common.nix ];

  options.modules.gaming.heroic = {
    enable = lib.mkEnableOption "Heroic Games Launcher (Epic/GOG)";

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
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      heroic
    ] ++ lib.optionals cfg.mangohud [
      mangohud
    ];

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
  };
}
