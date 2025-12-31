# Scream - low-latency audio from VM to host
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.vfio;
  # Safe access to bridge config (may not be loaded)
  netCfg = config.modules.networking.bridge or {};
in
{
  options.modules.vfio.scream = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Scream audio receiver for VM audio";
    };

    interface = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Network interface to listen on (defaults to bridge or virbr0)";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.scream.enable) {
    environment.systemPackages = [ pkgs.scream ];

    # Scream audio receiver as user service
    systemd.user.services.scream = {
      description = "Scream audio receiver";
      wantedBy = [ "graphical-session.target" ];
      after = [ "pipewire.service" ];
      serviceConfig = {
        ExecStart = let
          interface =
            if cfg.scream.interface != "" then cfg.scream.interface
            else if (netCfg.enable or false) then (netCfg.name or "virbr0")
            else "virbr0";
        in "${pkgs.scream}/bin/scream -i ${interface} -o pipewire";
        Restart = "always";
        RestartSec = "5";
      };
    };
  };
}
