#!/bin/bash

# List of VLAN IDs
VLAN_IDS=(101 102 201 202)

# Trunk interface
IFACE="end0"

# Function to bring up VLANs and bridges
function setup() {
  echo "[+] Setting up VLAN bridges..."
  sudo modprobe 8021q

  for vlan in "${VLAN_IDS[@]}"; do
    echo "  [+] Creating VLAN ${vlan} and br-vlan${vlan}"

    sudo ip link add link "$IFACE" name "${IFACE}.${vlan}" type vlan id "$vlan" 2>/dev/null || true
    sudo ip link set "${IFACE}.${vlan}" up

    sudo ip link add name "br-vlan${vlan}" type bridge 2>/dev/null || true
    sudo ip link set "br-vlan${vlan}" up

    sudo ip link set "${IFACE}.${vlan}" master "br-vlan${vlan}"
  done
  echo "[✓] VLAN bridges created."
}

# Function to tear down VLANs and bridges
function teardown() {
  echo "[-] Removing VLAN bridges..."
  for vlan in "${VLAN_IDS[@]}"; do
    echo "  [-] Deleting br-vlan${vlan} and ${IFACE}.${vlan}"
    
    sudo ip link set "br-vlan${vlan}" down 2>/dev/null || true
    sudo ip link delete "br-vlan${vlan}" type bridge 2>/dev/null || true

    sudo ip link set "${IFACE}.${vlan}" down 2>/dev/null || true
    sudo ip link delete "${IFACE}.${vlan}" 2>/dev/null || true
  done
  echo "[✓] VLAN bridges removed."
}

# Entry point
case "$1" in
  up)
    setup
    ;;
  down)
    teardown
    ;;
  *)
    echo "Usage: $0 {up|down}"
    exit 1
    ;;
esac
