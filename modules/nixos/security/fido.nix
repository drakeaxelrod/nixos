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
  authfile = pkgs.writeText "u2f-mappings" cfg.credentials;
  origin = "pam://${config.networking.hostName}";
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

      kde = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable U2F for KDE screen locker (kscreenlocker)";
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

    # libfido2 udev rules grant access to the 'plugdev' group — ensure it exists
    users.groups.plugdev = {};

    # SDDM greeter runs as the sddm system user. It needs to open the FIDO HID
    # device to issue challenges, but uaccess only covers the active logind session
    # user (draxel), not the greeter process. Adding sddm to plugdev gives it
    # the necessary device access at login time.
    users.users.sddm.extraGroups = lib.optional cfg.services.sddm "plugdev";

    # PAM U2F configuration
    security.pam.u2f = {
      enable = true;
      control = cfg.control;
      settings = {
        inherit authfile;
        cue = true;  # Show "Please touch the device" prompt
        inherit origin;
        appid = origin;
      };
    };

    # Enable U2F for selected PAM services
    security.pam.services = {
      login.u2f.enable = cfg.services.login;
      sudo.u2f.enable = cfg.services.sudo;
      polkit-1.u2f.enable = cfg.services.polkit;
      kde.u2f.enable = cfg.services.kde;
      kde-fingerprint.u2f.enable = cfg.services.kde;
    };

    # The SDDM nixpkgs module sets sddm.text directly (plain assignment, priority 100),
    # which overrides the PAM module's auto-generated text from rules (lib.mkDefault,
    # priority 1000). u2fAuth on the sddm service would generate a valid rule but it
    # would never appear in the PAM config file. Instead we use lib.mkForce (priority 50)
    # to win over the SDDM module's text and inject pam_u2f before the login substack.
    security.pam.services.sddm.text = lib.mkIf cfg.services.sddm (lib.mkForce ''
      auth      ${cfg.control}   ${pkgs.pam_u2f}/lib/security/pam_u2f.so authfile=${authfile} cue origin=${origin} appid=${origin} timeout=3
      auth      substack         login
      account   include          login
      password  substack         login
      session   include          login
    '');
  };
}
