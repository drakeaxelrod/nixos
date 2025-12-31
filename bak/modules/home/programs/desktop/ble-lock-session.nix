# =============================================================================
# BLE Lock Session - Bluetooth Proximity Screen Lock
# =============================================================================
#
# Automatically locks your screen when your Bluetooth device (e.g., phone)
# goes out of range, and unlocks when it returns.
#
# Usage:
#   services.ble-lock-session = {
#     enable = true;
#     targetAddress = "AA:BB:CC:DD:EE:FF";  # Your phone's MAC
#   };
#
# To find your device address:
#   bluetoothctl devices
#   # or
#   bluetoothctl scan on
#
# =============================================================================

{ config, pkgs, lib, ... }:

let
  cfg = config.services.ble-lock-session;

  # Environment file for systemd (handles spaces in values correctly)
  envFile = pkgs.writeText "ble-lock-session-env" ''
    BLE_TARGET_ADDRESS=${cfg.targetAddress}
    BLE_LOCK_CMD=${cfg.lockCommand}
    BLE_UNLOCK_CMD=${cfg.unlockCommand}
    BLE_CHECK_INTERVAL=${toString cfg.checkInterval}
    BLE_TIMEOUT=${toString cfg.timeout}
    BLE_RSSI_THRESHOLD=${toString cfg.rssiThreshold}
  '';

  # Our own simple Python script
  bleLockScript = pkgs.writeTextFile {
    name = "ble-lock-session";
    executable = true;
    destination = "/bin/ble-lock-session";
    text = ''
      #!${pkgs.python3}/bin/python3
      """
      BLE Lock Session - Lock/unlock screen based on Bluetooth device proximity.
      """

      import subprocess
      import time
      import sys
      import os
      from datetime import datetime

      TARGET_ADDRESS = os.environ.get("BLE_TARGET_ADDRESS", "")
      LOCK_CMD = os.environ.get("BLE_LOCK_CMD", "loginctl lock-session")
      UNLOCK_CMD = os.environ.get("BLE_UNLOCK_CMD", "loginctl unlock-session")
      CHECK_INTERVAL = int(os.environ.get("BLE_CHECK_INTERVAL", "5"))
      TIMEOUT = int(os.environ.get("BLE_TIMEOUT", "5"))
      RSSI_THRESHOLD = int(os.environ.get("BLE_RSSI_THRESHOLD", "-70"))

      def log(msg):
          timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
          print(f"[{timestamp}] {msg}", flush=True)

      def get_device_rssi(address):
          """Get RSSI (signal strength) for a device. Returns None if not found."""
          try:
              result = subprocess.run(
                  ["${pkgs.bluez}/bin/bluetoothctl", "info", address],
                  capture_output=True,
                  text=True,
                  timeout=TIMEOUT
              )

              # Parse RSSI from output (format: "RSSI: -XX")
              for line in result.stdout.split('\n'):
                  if "RSSI:" in line:
                      try:
                          rssi = int(line.split(':')[1].strip().split()[0])
                          return rssi
                      except (ValueError, IndexError):
                          pass
              return None
          except Exception:
              return None

      def is_device_present(address):
          """Check if device is connected or nearby using bluetoothctl."""
          try:
              # Check device info - works for paired devices
              result = subprocess.run(
                  ["${pkgs.bluez}/bin/bluetoothctl", "info", address],
                  capture_output=True,
                  text=True,
                  timeout=TIMEOUT
              )

              # If device is connected, it's definitely present
              if "Connected: yes" in result.stdout:
                  # Check RSSI if threshold is set
                  rssi = get_device_rssi(address)
                  if rssi is not None:
                      log(f"Device connected, RSSI: {rssi} dBm (threshold: {RSSI_THRESHOLD})")
                      return rssi >= RSSI_THRESHOLD
                  return True

              # Check if device exists and is paired
              if "Device" not in result.stdout:
                  log(f"Device {address} not found - is it paired?")
                  return False

              # Try to connect briefly to check if device is in range
              # This works even if the device doesn't accept connections
              result = subprocess.run(
                  ["${pkgs.bluez}/bin/bluetoothctl", "connect", address],
                  capture_output=True,
                  text=True,
                  timeout=TIMEOUT
              )

              # Check if connection succeeded or device responded
              if result.returncode == 0:
                  # Check RSSI now that we're connected
                  rssi = get_device_rssi(address)
                  if rssi is not None:
                      log(f"Device found, RSSI: {rssi} dBm (threshold: {RSSI_THRESHOLD})")
                      in_range = rssi >= RSSI_THRESHOLD
                  else:
                      in_range = True

                  # Disconnect to not drain phone battery
                  subprocess.run(
                      ["${pkgs.bluez}/bin/bluetoothctl", "disconnect", address],
                      capture_output=True,
                      timeout=2
                  )
                  return in_range

              # Check for "not available" which means device is out of range
              if "not available" in result.stderr.lower() or "not available" in result.stdout.lower():
                  return False

              # Page Timeout means device is not in range
              if "Page Timeout" in result.stdout:
                  return False

              # Other connection failures might still mean device is nearby
              return False

          except subprocess.TimeoutExpired:
              return False
          except Exception as e:
              log(f"Error checking device: {e}")
              return False

      def run_command(cmd):
          """Run a shell command."""
          try:
              subprocess.run(cmd, shell=True, check=False)
          except Exception as e:
              log(f"Error running command: {e}")

      def main():
          if not TARGET_ADDRESS:
              print("Error: BLE_TARGET_ADDRESS not set")
              print("Set it in your NixOS config: services.ble-lock-session.targetAddress")
              sys.exit(1)

          log(f"Starting BLE Lock Session")
          log(f"Monitoring device: {TARGET_ADDRESS}")
          log(f"Lock command: {LOCK_CMD}")
          log(f"Unlock command: {UNLOCK_CMD}")
          log(f"Check interval: {CHECK_INTERVAL}s")

          # State: True = unlocked (device present), False = locked (device away)
          device_present = True
          consecutive_failures = 0
          FAILURE_THRESHOLD = 3  # Lock after 3 consecutive failures

          while True:
              try:
                  is_present = is_device_present(TARGET_ADDRESS)

                  if is_present:
                      consecutive_failures = 0
                      if not device_present:
                          log("Device detected - UNLOCKING")
                          run_command(UNLOCK_CMD)
                          device_present = True
                  else:
                      consecutive_failures += 1
                      if device_present and consecutive_failures >= FAILURE_THRESHOLD:
                          log(f"Device not detected ({consecutive_failures} checks) - LOCKING")
                          run_command(LOCK_CMD)
                          device_present = False

                  time.sleep(CHECK_INTERVAL)

              except KeyboardInterrupt:
                  log("Stopped by user")
                  break
              except Exception as e:
                  log(f"Error: {e}")
                  time.sleep(CHECK_INTERVAL)

      if __name__ == "__main__":
          main()
    '';
  };

in
{
  options.services.ble-lock-session = {
    enable = lib.mkEnableOption "BLE Lock Session - auto lock/unlock via Bluetooth proximity";

    targetAddress = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "AA:BB:CC:DD:EE:FF";
      description = "Bluetooth MAC address of the device to monitor. Find with: bluetoothctl devices";
    };

    lockCommand = lib.mkOption {
      type = lib.types.str;
      default = "loginctl lock-session";
      description = "Command to run when device goes out of range";
    };

    unlockCommand = lib.mkOption {
      type = lib.types.str;
      default = "loginctl unlock-session";
      description = "Command to run when device comes back in range";
    };

    checkInterval = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Seconds between Bluetooth checks";
    };

    timeout = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Bluetooth ping timeout in seconds";
    };

    rssiThreshold = lib.mkOption {
      type = lib.types.int;
      default = -70;
      description = ''
        RSSI (signal strength) threshold in dBm. Device is considered "away"
        when signal drops below this value. More negative = weaker signal.

        Approximate RSSI to distance mapping (varies by environment):
          -30 dBm : Excellent - device is very close (< 1m / 3ft)
          -50 dBm : Good      - device is nearby (1-3m / 3-10ft)
          -60 dBm : Fair      - device is in the room (3-5m / 10-16ft)
          -70 dBm : Weak      - device is farther away (5-10m / 16-33ft)
          -80 dBm : Poor      - device is at edge of range (10-15m / 33-50ft)
          -90 dBm : Very poor - device barely detectable

        Walls, interference, and phone position affect readings significantly.
        Start with -70 (default) and adjust based on your setup.
        Use "bluetoothctl info <MAC>" while moving around to find your ideal value.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ bleLockScript ];

    # Systemd user service
    systemd.user.services.ble-lock-session = {
      Unit = {
        Description = "BLE Lock Session - Auto lock/unlock via Bluetooth proximity";
        After = [ "bluetooth.target" "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        EnvironmentFile = "${envFile}";
        ExecStart = "${bleLockScript}/bin/ble-lock-session";
        Restart = "on-failure";
        RestartSec = "10";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
