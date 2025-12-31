# SOPS secrets management - Hierarchical system
{ config, lib, pkgs, inputs, ... }:

let
  hostname = config.networking.hostName;
  # Secrets are stored in hosts/<hostname>/secrets.yaml
  hostSecretsFile = ../../hosts/${hostname}/secrets.yaml;
in
{
  options.modules.security.sops = {
    enable = lib.mkEnableOption "SOPS secrets management";

    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/ssh/ssh_host_ed25519_key";
      description = "Path to age key file for decryption (host SSH key)";
    };

    hostSecretsFile = lib.mkOption {
      type = lib.types.path;
      default = hostSecretsFile;
      description = "Path to host-specific secrets file";
      example = lib.literalExpression "../../hosts/\${hostname}/secrets.yaml";
    };

    extraSecrets = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional secrets to define manually";
      example = lib.literalExpression ''
        {
          "my-secret" = {
            sopsFile = ./secrets/custom.yaml;
            owner = "myuser";
          };
        }
      '';
    };
  };

  config = lib.mkIf config.modules.security.sops.enable {
    sops = {
      # Use host SSH key for decryption
      age.sshKeyPaths = [ config.modules.security.sops.ageKeyFile ];

      # Default to host-specific secrets file
      defaultSopsFile = config.modules.security.sops.hostSecretsFile;

      # Define secrets to decrypt
      # Available at /run/secrets/<name>
      #
      # Secrets are automatically loaded from hosts/<hostname>/secrets.yaml
      # Define them here to make them available to the system:
      #
      # secrets = {
      #   wifi_password = {};  # Uses defaultSopsFile
      #   root_password_hash = {};
      #
      #   # User-specific secret from different file
      #   "draxel-git-token" = {
      #     sopsFile = ../../users/draxel/secrets.yaml;
      #     owner = "draxel";
      #   };
      # };
      #
      # Or use extraSecrets option below
      secrets = config.modules.security.sops.extraSecrets;
    };
  };
}
