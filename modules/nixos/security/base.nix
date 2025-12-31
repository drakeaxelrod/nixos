# Security configuration
{ config, lib, ... }:

{
  options.modules.security.base = {
    enable = lib.mkEnableOption "base security settings";
  };

  config = lib.mkIf config.modules.security.base.enable {
    # Sudo configuration
    security.sudo.wheelNeedsPassword = true;

    # Polkit for GUI privilege escalation
    security.polkit.enable = true;

    # Realtime scheduling for audio
    security.rtkit.enable = true;
  };
}
