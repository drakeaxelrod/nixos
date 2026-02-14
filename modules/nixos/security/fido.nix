# FIDO2/U2F authentication for login, sudo, and SSH
#
# Enables passwordless authentication using FIDO2 hardware security keys
# (YubiKey, Google Titan Key, SoloKeys, etc).
# Supports login, sudo, display manager (SDDM), and SSH authentication.
#
# PAM Setup (login/sudo/sddm):
#   1. Enable this module
#   2. Run: pamu2fcfg -o pam://hostname -i pam://hostname
#   3. Touch your security key when it blinks
#   4. Add the output to the credentials option
#   5. Repeat for each key you want to enroll (one line per key)
#
# SSH Setup (FIDO2 resident keys):
#   1. Enable ssh option in this module
#   2. Generate key: ssh-keygen -t ed25519-sk -O resident -O application=ssh:github
#   3. Touch your key when prompted
#   4. Add ~/.ssh/id_ed25519_sk.pub to GitHub/GitLab
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.security.fido;
in
{
  options.modules.security.fido = {
    enable = lib.mkEnableOption "FIDO2/U2F hardware key authentication";

    control = lib.mkOption {
      type = lib.types.enum [ "sufficient" "required" "requisite" ];
      default = "sufficient";
      description = ''
        PAM control mode:
        - sufficient: Security key OR password works (recommended)
        - required: Security key AND password required
        - requisite: Security key required, fail immediately if missing
      '';
    };

    credentials = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        U2F credential mappings for all enrolled keys.
        Generate with: pamu2fcfg -o pam://$(hostname) -i pam://$(hostname)
        Add one line per key (YubiKey, Titan Key, etc).

        Format: username:KeyHandle,PublicKey,CoseType,Options
      '';
      example = ''
        draxel:YUBIKEY_CREDENTIAL_HERE
        draxel:TITANKEY_CREDENTIAL_HERE
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

    yubikey = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable YubiKey-specific packages (ykman, pcscd, udev rules)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Core FIDO2 packages
    environment.systemPackages = with pkgs; [
      libfido2  # fido2-token CLI + FIDO2 library for SSH sk keys
      pam_u2f   # PAM module for U2F
    ] ++ lib.optionals cfg.yubikey [
      yubikey-manager  # ykman CLI tool
    ];

    # Smart card daemon (required for YubiKey management)
    services.pcscd.enable = lib.mkIf cfg.yubikey true;

    # udev rules for device access
    services.udev.packages = [ pkgs.libfido2 ]
      ++ lib.optionals cfg.yubikey [ pkgs.yubikey-personalization ];

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
