# YubiKey U2F/FIDO2 authentication for login, sudo, and SSH
#
# Enables passwordless authentication using YubiKey hardware tokens.
# Supports login, sudo, display manager (SDDM), and SSH authentication.
#
# PAM Setup (login/sudo/sddm):
#   1. Enable this module
#   2. Run: pamu2fcfg -o pam://hostname -i pam://hostname
#   3. Touch your YubiKey when it blinks
#   4. Add the output to the credentials option
#
# SSH Setup (FIDO2 resident keys):
#   1. Enable ssh option in this module
#   2. Generate key: ssh-keygen -t ed25519-sk -O resident -O application=ssh:github
#   3. Touch YubiKey when prompted
#   4. Add ~/.ssh/id_ed25519_sk.pub to GitHub/GitLab
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.security.yubikey;
in
{
  options.modules.security.yubikey = {
    enable = lib.mkEnableOption "YubiKey U2F/FIDO2 authentication";

    control = lib.mkOption {
      type = lib.types.enum [ "sufficient" "required" "requisite" ];
      default = "sufficient";
      description = ''
        PAM control mode:
        - sufficient: YubiKey OR password works (recommended)
        - required: YubiKey AND password required
        - requisite: YubiKey required, fail immediately if missing
      '';
    };

    credentials = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        U2F credential mappings. Generate with:
          pamu2fcfg -o pam://$(hostname) -i pam://$(hostname)

        Format: username:KeyHandle,PublicKey,CoseType,Options
      '';
      example = ''
        draxel:ABCdef123...
      '';
    };

    services = {
      login = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable U2F for console login";
      };

      sudo = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable U2F for sudo";
      };

      sddm = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable U2F for SDDM display manager";
      };

      polkit = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable U2F for Polkit authentication dialogs";
      };
    };

    ssh = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable FIDO2 SSH key support.
        After enabling, generate a resident key with:
          ssh-keygen -t ed25519-sk -O resident -O application=ssh:github
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Required packages for YubiKey management and enrollment
    environment.systemPackages = with pkgs; [
      yubikey-manager  # ykman CLI tool
      pam_u2f          # PAM module for U2F
    ] ++ lib.optionals cfg.ssh [
      libfido2         # FIDO2 library for SSH sk keys
    ];

    # Enable smart card daemon (required for some YubiKey features)
    services.pcscd.enable = true;

    # udev rules for YubiKey access
    services.udev.packages = [ pkgs.yubikey-personalization ];

    # PAM U2F configuration
    security.pam.u2f = {
      enable = true;
      control = cfg.control;
      settings = {
        authfile = pkgs.writeText "u2f-mappings" cfg.credentials;
        cue = true;  # Show "Please touch the device" prompt
      };
    };

    # Enable U2F for selected PAM services
    security.pam.services = {
      login.u2fAuth = cfg.services.login;
      sudo.u2fAuth = cfg.services.sudo;
      sddm.u2fAuth = cfg.services.sddm;
      polkit-1.u2fAuth = cfg.services.polkit;
    };
  };
}
