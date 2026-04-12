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
        AllowAgentForwarding = true;
        # Explicitly allow FIDO2 SSH key types
        PubkeyAcceptedAlgorithms = "ssh-ed25519,sk-ssh-ed25519@openssh.com,sk-ecdsa-sha2-nistp256@openssh.com,ssh-rsa,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521";
      };
    };
  };
}
