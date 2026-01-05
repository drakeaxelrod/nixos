# Epic Games - Epic Games Store access on Linux
#
# Options:
#   - legendary: CLI-based Epic Games client (lightweight, no GUI)
#   - rare: GUI frontend for Legendary
#   - heroic: Full-featured launcher (also supports GOG) - use heroic.nix instead
#
# Note: The official Epic Games Launcher requires Wine/Proton.
# For the best experience, use Heroic Games Launcher (modules.gaming.heroic)
# which provides a native Linux GUI with Epic Games and GOG support.
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.gaming.epic;
in
{
  imports = [ ./common.nix ];

  options.modules.gaming.epic = {
    enable = lib.mkEnableOption "Epic Games Store access";

    client = lib.mkOption {
      type = lib.types.enum [ "legendary" "rare" ];
      default = "rare";
      description = ''
        Which Epic Games client to use:
        - legendary: CLI-only client (lightweight)
        - rare: GUI frontend for Legendary

        For a full launcher experience, consider using modules.gaming.heroic instead.
      '';
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
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Legendary CLI (always included as backend)
      [ legendary-gl ] ++
      # Rare GUI frontend
      lib.optionals (cfg.client == "rare") [ rare ] ++
      # MangoHud
      lib.optionals cfg.mangohud [ mangohud ];

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
