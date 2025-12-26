# Dynamic network bridge for VM passthrough
# Provides commands to create/destroy bridges on any interface
{ config, pkgs, lib, vars, ... }:

{
  # Fix for GDM black screen - wait for network before starting display manager
  #systemd.services.display-manager.after = [ "network-online.target" ];
  #systemd.services.display-manager.wants = [ "network-online.target" ];

  # Allow asymmetric routing for VM bridged networking
  networking.firewall.checkReversePath = "loose";

  # Trust bridge interfaces
  networking.firewall.trustedInterfaces = [ "br0" "virbr0" ];

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "vm-bridge-up" ''
      # Create a bridge on the specified interface
      # Usage: vm-bridge-up <interface>
      # Example: vm-bridge-up eno1
      #          vm-bridge-up wlp6s0

      set -e
      IFACE="''${1:-}"
      BRIDGE="br0"

      if [ -z "$IFACE" ]; then
        echo "Usage: vm-bridge-up <interface>"
        echo ""
        echo "Available interfaces:"
        ip -br link show | grep -v -E "^(lo|br|vir|docker|veth|tap)" | awk '{print "  " $1}'
        exit 1
      fi

      if ip link show "$BRIDGE" &>/dev/null; then
        echo "Bridge $BRIDGE already exists. Run vm-bridge-down first."
        exit 1
      fi

      echo "Creating bridge $BRIDGE with $IFACE..."

      # Create bridge connection
      nmcli con add type bridge ifname "$BRIDGE" con-name "$BRIDGE" \
        bridge.stp no \
        ipv4.method auto \
        ipv6.method auto

      # Add interface as slave
      nmcli con add type bridge-slave ifname "$IFACE" master "$BRIDGE" con-name "$BRIDGE-slave"

      # Disconnect the interface's current connection
      CURRENT_CON=$(nmcli -t -f NAME,DEVICE con show --active | grep ":$IFACE$" | cut -d: -f1)
      if [ -n "$CURRENT_CON" ]; then
        echo "Disconnecting $CURRENT_CON..."
        nmcli con down "$CURRENT_CON" || true
      fi

      # Bring up the bridge
      nmcli con up "$BRIDGE-slave"
      nmcli con up "$BRIDGE"

      echo ""
      echo "Bridge $BRIDGE is up with $IFACE"
      echo "VMs can now use bridge '$BRIDGE' for networking"
    '')

    (pkgs.writeShellScriptBin "vm-bridge-down" ''
      # Tear down the VM bridge and restore normal networking
      # Usage: vm-bridge-down

      set -e
      BRIDGE="br0"

      if ! ip link show "$BRIDGE" &>/dev/null; then
        echo "Bridge $BRIDGE does not exist."
        exit 0
      fi

      echo "Tearing down bridge $BRIDGE..."

      # Get the slave interface before we destroy everything
      SLAVE_IFACE=$(bridge link show | grep "master $BRIDGE" | awk '{print $2}' | tr -d ':')

      # Delete bridge connections
      nmcli con delete "$BRIDGE-slave" 2>/dev/null || true
      nmcli con delete "$BRIDGE" 2>/dev/null || true

      # Reconnect the interface to its original connection
      if [ -n "$SLAVE_IFACE" ]; then
        echo "Restoring connection on $SLAVE_IFACE..."
        # Find a connection for this interface and bring it up
        ORIG_CON=$(nmcli -t -f NAME,DEVICE,TYPE con show | grep -E ":$SLAVE_IFACE:|:ethernet:" | grep -v bridge | head -1 | cut -d: -f1)
        if [ -n "$ORIG_CON" ]; then
          nmcli con up "$ORIG_CON" || true
        else
          # Try to auto-connect
          nmcli device connect "$SLAVE_IFACE" || true
        fi
      fi

      echo "Bridge torn down. Normal networking restored."
    '')

    (pkgs.writeShellScriptBin "vm-bridge-status" ''
      # Show bridge status
      BRIDGE="br0"

      echo "=== VM Bridge Status ==="
      echo ""

      if ip link show "$BRIDGE" &>/dev/null; then
        echo "Bridge $BRIDGE: ACTIVE"
        echo ""
        echo "Bridge IP:"
        ip -br addr show "$BRIDGE" | awk '{print "  " $3}'
        echo ""
        echo "Bridge members:"
        bridge link show master "$BRIDGE" 2>/dev/null | awk '{print "  " $2}' | tr -d ':'
      else
        echo "Bridge $BRIDGE: NOT ACTIVE"
        echo ""
        echo "To create a bridge, run:"
        echo "  vm-bridge-up <interface>"
        echo ""
        echo "Available interfaces:"
        ip -br link show | grep -v -E "^(lo|br|vir|docker|veth|tap)" | awk '{print "  " $1}'
      fi
    '')
  ];
}
