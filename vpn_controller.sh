#!/bin/bash
#
# vpn_controller.sh - NordVPN controller with auto-update and version checking
# Author: Jeremiah O'Neal
# License: MIT License (Recommended)
#
# Description:
# This script resets network configurations, connects to NordVPN, and supports
# self-updating by comparing local and remote script versions hosted on GitHub.

VERSION="1.0.2"
SCRIPT_PATH="$(realpath "$0")"
REMOTE_URL="https://raw.githubusercontent.com/we6jbo/VPNFix/main/vpn_controller.sh"

# Function: Reset Network
reset_network() {
    echo "🚑 Resetting network to bypass NordVPN..."
    iptables -F
    nft flush ruleset
    echo "Stopping NordVPN service..."
    systemctl unmask nordvpn || echo "NordVPN service was not masked or unmasking failed."
    systemctl stop nordvpn || echo "NordVPN service not running."
    ip route del default || echo "Default route not found."
    echo "✅ Network reset complete."
}

# Function: Connect to VPN
connect_vpn() {
    echo "🔗 Connecting to NordVPN..."
    nordvpn login || echo "Already logged in or login error."
    nordvpn connect || echo "VPN connection failed."
    echo "🔍 VPN Status:"
    curl -s ifconfig.me && echo ""
    ip route
    nordvpn status
}

# Function: Fetch Remote Version
fetch_remote_version() {
    curl -fsSL "$REMOTE_URL" | grep -E '^VERSION=' | cut -d'=' -f2 | tr -d '"'
}

# Function: Update Script
update_script() {
    echo "🔄 Attempting to update script from remote..."
    cp "$SCRIPT_PATH" "${SCRIPT_PATH}.bak"
    if curl -fsSL "$REMOTE_URL" -o "$SCRIPT_PATH"; then
        chmod +x "$SCRIPT_PATH"
        echo "✅ Script updated successfully!"
    else
        echo "❌ Update failed. Restoring backup..."
        mv "${SCRIPT_PATH}.bak" "$SCRIPT_PATH"
    fi
}

# Function: Check for Update
check_update() {
    REMOTE_VERSION=$(fetch_remote_version)
    echo "🔎 Local version: $VERSION"
    echo "🌐 Remote version: $REMOTE_VERSION"
    if [ -z "$REMOTE_VERSION" ]; then
        echo "⚠️ Could not fetch remote version. Skipping update check."
    elif [ "$REMOTE_VERSION" != "$VERSION" ]; then
        echo "🚨 A newer version is available!"
        echo "📥 Updating script..."
        update_script
        echo "🔄 Restarting with updated script..."
        exec "$SCRIPT_PATH" "$@"
        exit 0
    else
        echo "✅ You are up-to-date!"
    fi
}

# Entry Point
case "$1" in
    reset)
        check_update "$@"
        reset_network
        ;;
    connect)
        check_update "$@"
        connect_vpn
        ;;
    update)
        update_script
        ;;
    check-update)
        check_update
        ;;
    *)
        echo "Usage: $0 {reset|connect|update|check-update}"
        ;;
esac

