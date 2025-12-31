# SOPS secrets management
{ config, lib, pkgs, inputs, ... }:

{
  options.modules.security.sops = {
    enable = lib.mkEnableOption "SOPS secrets management";

    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/persist/etc/sops/age/keys.txt";
      description = "Path to age key file for decryption";
    };

    secretsFile = lib.mkOption {
      type = lib.types.path;
      default = ../../secrets/secrets.yaml;
      description = "Path to SOPS secrets file";
    };
  };

  config = lib.mkIf config.modules.security.sops.enable {
    sops = {
      defaultSopsFile = config.modules.security.sops.secretsFile;
      age.keyFile = config.modules.security.sops.ageKeyFile;

      # Define secrets to decrypt
      # These will be available at /run/secrets/<name>
      secrets = {
        # Example secrets - uncomment when secrets.yaml is created
        # tailscale-authkey = {};
        # git-email = {};
        # wifi-password = {};
      };
    };
  };
}
