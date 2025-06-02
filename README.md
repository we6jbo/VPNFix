# VPNFix

A simple bash script to manage NordVPN connections on Linux, including reset and reconnect functionality, version-checking, and auto-updating from GitHub.

## Features
- Reset network settings to bypass NordVPN issues.
- Connect to NordVPN with NordLynx protocol.
- Version-check and auto-update from this repository.
- Logs IP address, routing table, and VPN status for troubleshooting.

## Usage

```bash
# Reset VPN settings
./vpn_controller.sh reset

# Connect to VPN
./vpn_controller.sh connect

# Check for script updates
./vpn_controller.sh check-update

# Force update
./vpn_controller.sh update
