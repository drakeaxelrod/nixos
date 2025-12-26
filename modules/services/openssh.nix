# OpenSSH server
{ config, lib, pkgs, ... }:

{
  options.modules.services.openssh = {
    enable = lib.mkEnableOption "OpenSSH server";
  };

  config = lib.mkIf config.modules.services.openssh.enable {
    services.openssh.enable = true;
  };
}
