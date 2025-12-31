# Steam - Gaming Platform
{ config, lib, ... }:

{
  options.modules.desktop.steam = {
    enable = lib.mkEnableOption "Steam gaming platform";
  };

  config = lib.mkIf config.modules.desktop.steam.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;  # Open ports for Steam Remote Play
      dedicatedServer.openFirewall = true;  # Open ports for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true;  # Open ports for Steam Local Network Game Transfers
    };
  };
}
