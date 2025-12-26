# User management module
{ config, lib, pkgs, ... }:

{
  options.modules.users = {
    primaryUser = lib.mkOption {
      type = lib.types.str;
      default = "draxel";
      description = "Primary user account name";
    };

    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          description = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          shell = lib.mkOption {
            type = lib.types.package;
            default = pkgs.zsh;
          };
          extraGroups = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "wheel" "networkmanager" ];
          };
          initialPassword = lib.mkOption {
            type = lib.types.str;
            default = "changeme";
          };
        };
      });
      default = {};
      description = "User account definitions";
    };
  };

  config = {
    # Enable zsh system-wide if any user uses it
    programs.zsh.enable = true;

    # Create user accounts
    users.users = lib.mapAttrs (name: cfg: {
      isNormalUser = true;
      description = cfg.description;
      shell = cfg.shell;
      extraGroups = cfg.extraGroups;
      initialPassword = cfg.initialPassword;
    }) config.modules.users.users;
  };
}
