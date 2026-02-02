# Audio - PipeWire
{ config, lib, pkgs, ... }:

{
  options.modules.hardware.audio = {
    enable = lib.mkEnableOption "PipeWire audio support";

    enableJack = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable JACK support for professional audio";
    };

    enableNetworkDiscovery = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable mDNS/Avahi for WiFi speaker discovery (Spotify Connect, Sonos, Chromecast, etc.)";
    };
  };

  config = lib.mkIf config.modules.hardware.audio.enable {
    # Disable PulseAudio (replaced by PipeWire)
    services.pulseaudio.enable = false;

    # Realtime scheduling for low-latency audio
    security.rtkit.enable = true;

    # PipeWire configuration
    services.pipewire = {
      enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };

      pulse.enable = true;
      jack.enable = config.modules.hardware.audio.enableJack;
    };

    # mDNS/Avahi for WiFi speaker discovery
    services.avahi = lib.mkIf config.modules.hardware.audio.enableNetworkDiscovery {
      enable = true;
      nssmdns4 = true;
    };
  };
}
