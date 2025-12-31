# OpenSSH server
{ config, lib, pkgs, ... }:

{
  options.modules.services.openssh = {
    enable = lib.mkEnableOption "OpenSSH server";
  };

  config = lib.mkIf config.modules.services.openssh.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PubkeyAuthentication = true;
        PermitRootLogin = "no";
        MaxAuthTries = 3;
        X11Forwarding = true;
        X11UseLocalhost = true;
      };
    };
  };
}
