# Security configuration
{ config, pkgs, lib, ... }:

{
  # Sudo configuration
  security.sudo.wheelNeedsPassword = true;

  # Polkit for GUI privilege escalation
  security.polkit.enable = true;

  # Realtime scheduling for audio
  security.rtkit.enable = true;
}
