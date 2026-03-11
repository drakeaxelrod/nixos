# Touchegg - multi-touch gesture recognition
#
# Provides touchpad gestures (swipe, pinch, tap) with configurable actions.
# Gestures are defined declaratively and rendered to touchegg XML config.
#
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.hardware.touchegg;

  # Render a single gesture to XML
  gestureToXml = g: ''
    <gesture type="${g.type}" fingers="${toString g.fingers}" direction="${g.direction}">
      <action type="${g.action}">
        <repeat>${if g.repeat then "true" else "false"}</repeat>
        ${lib.optionalString (g.command != null) "<command>${g.command}</command>"}
        ${lib.optionalString (g.on != null) "<on>${g.on}</on>"}
        ${lib.optionalString (g.amount != null) "<amount>${toString g.amount}</amount>"}
        ${lib.optionalString (g.angle != null) "<angle>${toString g.angle}</angle>"}
      </action>
    </gesture>
  '';

  # Render all gestures to full XML config
  configXml = ''
    <touchégg>
      <settings>
        <property name="animation_delay">${toString cfg.settings.animationDelay}</property>
        <property name="action_execute_threshold">${toString cfg.settings.actionExecuteThreshold}</property>
        <property name="color">${cfg.settings.color}</property>
        <property name="borderColor">${cfg.settings.borderColor}</property>
      </settings>
      <application name="All">
        ${lib.concatMapStringsSep "\n    " gestureToXml cfg.gestures}
      </application>
    </touchégg>
  '';

  gestureOpts = { ... }: {
    options = {
      type = lib.mkOption {
        type = lib.types.enum [ "SWIPE" "PINCH" "TAP" ];
        description = "Gesture type.";
      };
      fingers = lib.mkOption {
        type = lib.types.int;
        description = "Number of fingers.";
      };
      direction = lib.mkOption {
        type = lib.types.enum [ "UP" "DOWN" "LEFT" "RIGHT" "IN" "OUT" "ANY" ];
        description = "Gesture direction.";
      };
      action = lib.mkOption {
        type = lib.types.str;
        description = "Action type (e.g. RUN_COMMAND, SEND_KEYS, CHANGE_DESKTOP).";
      };
      command = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Command to run (for RUN_COMMAND action).";
      };
      repeat = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to repeat the action.";
      };
      on = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [ "begin" "update" "end" ]);
        default = null;
        description = "When to trigger the action.";
      };
      amount = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Amount for the action (e.g. pixels to move).";
      };
      angle = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Angle for the action (e.g. rotation degrees).";
      };
    };
  };
in
{
  options.modules.hardware.touchegg = {
    enable = lib.mkEnableOption "Touchegg multi-touch gesture support";

    settings = {
      animationDelay = lib.mkOption {
        type = lib.types.int;
        default = 150;
        description = "Delay before gesture animation starts (ms).";
      };
      actionExecuteThreshold = lib.mkOption {
        type = lib.types.int;
        default = 20;
        description = "Percentage of gesture to complete before action executes.";
      };
      color = lib.mkOption {
        type = lib.types.str;
        default = "auto";
        description = "Animation color.";
      };
      borderColor = lib.mkOption {
        type = lib.types.str;
        default = "auto";
        description = "Animation border color.";
      };
    };

    gestures = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule gestureOpts);
      default = [];
      description = "List of gesture definitions.";
    };

    plasma = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable default KDE Plasma gesture preset (3/4-finger swipes).";
    };

    enableGUI = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install Touche GUI (Flatpak) for visual gesture configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable the touchegg daemon
    services.touchegg.enable = true;

    # Default Plasma gestures when plasma preset is enabled
    modules.hardware.touchegg.gestures = lib.mkIf cfg.plasma [
      { type = "SWIPE"; fingers = 3; direction = "UP";    action = "RUN_COMMAND"; command = ''qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Overview"''; on = "begin"; }
      { type = "SWIPE"; fingers = 3; direction = "DOWN";  action = "RUN_COMMAND"; command = ''qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Show Desktop"''; on = "begin"; }
      { type = "SWIPE"; fingers = 3; direction = "LEFT";  action = "RUN_COMMAND"; command = ''qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Switch to Next Desktop"''; on = "begin"; }
      { type = "SWIPE"; fingers = 3; direction = "RIGHT"; action = "RUN_COMMAND"; command = ''qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Switch to Previous Desktop"''; on = "begin"; }
      { type = "SWIPE"; fingers = 4; direction = "UP";    action = "RUN_COMMAND"; command = ''qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Show Desktop"''; on = "begin"; }
      { type = "SWIPE"; fingers = 4; direction = "DOWN";  action = "RUN_COMMAND"; command = ''qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Overview"''; on = "begin"; }
    ];

    # Write system-level config to /etc/xdg/ via system profile
    # (environment.etc doesn't work for /etc/xdg/ on NixOS - it's assembled from profiles)
    environment.systemPackages = [
      (pkgs.writeTextDir "etc/xdg/touchegg/touchegg.conf" configXml)
    ];
    environment.pathsToLink = [ "/etc/xdg/touchegg" ];

    # Touche GUI (Flatpak) for visual gesture editing
    modules.services.flatpak = lib.mkIf cfg.enableGUI {
      enable = true;
      packages = [ "com.github.joseexposito.touche" ];
    };

    # Touche needs XDG_CONFIG_DIRS override to detect touchegg on NixOS
    # Also needs /nix/store access since /etc/xdg symlinks into the store
    system.activationScripts.toucheFlatpakOverride = lib.mkIf cfg.enableGUI ''
      ${pkgs.flatpak}/bin/flatpak override --user \
        --env=XDG_CONFIG_DIRS=/var/run/host/etc/xdg \
        --filesystem=/nix/store:ro \
        com.github.joseexposito.touche 2>/dev/null || true
    '';
  };
}
