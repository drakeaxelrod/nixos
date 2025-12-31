# Audio - PipeWire
{ config, pkgs, lib, ... }:

{
  # Disable PulseAudio
  services.pulseaudio.enable = false;

  # Enable realtime scheduling for audio
  security.rtkit.enable = true;

  # PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;  # Enable if needed for pro audio
  };
}
