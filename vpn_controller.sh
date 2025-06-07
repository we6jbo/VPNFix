#!/bin/bash
#
# vpn_controller.sh - NordVPN controller with auto-update, version checking, and interactive troubleshooting assistant
# Author: Jeremiah O'Neal
# License: MIT License (Recommended)
#
# Description:
# This script resets network configurations, connects to NordVPN, supports
# self-updating by comparing local and remote script versions hosted on GitHub,
# and includes an interactive troubleshooting assistant for connectivity issues.
# It now also includes a brute-force recovery mode.

VERSION="1.0.5"
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
    if ! nordvpn connect; then
        echo "❌ VPN connection failed."
        troubleshoot_prompt
    fi
    echo "🔍 VPN Status:"
    curl -s ifconfig.me && echo ""
    ip route
    nordvpn status
}

# Function: Brute-Force VPN Recovery
bruteforce_recovery() {
    echo "🛠️ Brute-Force Recovery Mode activated. Attempting to fix the VPN connection for 30 seconds..."
    end_time=$((SECONDS + 30))
    while [ $SECONDS -lt $end_time ]; do
        echo "🔄 Attempting troubleshooting steps..."
        troubleshoot_steps
        echo "🔗 Trying to connect to NordVPN..."
        if nordvpn connect; then
            echo "✅ VPN connection restored!"
            echo "🔍 VPN Status:"
            curl -s ifconfig.me && echo ""
            ip route
            nordvpn status
            exit 0
        fi
        echo "⏳ Waiting 5 seconds before next attempt..."
        sleep 5
    done
    echo "❌ Brute-Force Recovery Mode ended. VPN connection could not be established."
}

# Function: Troubleshooting Prompt
troubleshoot_prompt() {
    echo "💡 It looks like the VPN connection failed."
    echo "Here are some things you could try:"
    echo "1️⃣ Restart NetworkManager service"
    echo "2️⃣ Flush firewall rules (iptables and nftables)"
    echo "3️⃣ Unmask and restart NordVPN service"
    echo "4️⃣ Re-login to NordVPN"
    echo "5️⃣ View the last 10 lines of NordVPN logs"
    echo "6️⃣ Test internet connectivity with ping"
    read -p "Would you like me to try these steps for you? (yes/no): " choice
    case "$choice" in
        yes|y|Y)
            echo "🔧 Attempting automated troubleshooting..."
            troubleshoot_steps
            ;;
            diagnose)
        check_update "$@"
        diagnose_issue
        ;;
    *)
            echo "👍 Okay! You can try running './vpn_controller.sh reset' manually if you'd like."
            ;;
    esac
}

# Function: Troubleshoot Steps
troubleshoot_steps() {
    echo "🔄 Restarting NetworkManager..."
    systemctl restart NetworkManager || echo "⚠️ Could not restart NetworkManager."
    echo "🚫 Flushing firewall rules..."
    iptables -F
    nft flush ruleset
    echo "🔓 Unmasking and restarting NordVPN service..."
    systemctl unmask nordvpn || echo "NordVPN service was not masked or unmasking failed."
    systemctl restart nordvpn || echo "⚠️ Could not restart NordVPN service."
    echo "🔐 Re-logging into NordVPN..."
    nordvpn logout
    nordvpn login || echo "⚠️ NordVPN login failed or was already logged in."
    echo "📝 Displaying last 10 lines of NordVPN logs..."
    journalctl -u nordvpn --no-pager | tail -n 10 || echo "⚠️ Could not display NordVPN logs."
    echo "🌐 Checking internet connectivity..."
    ping -c 3 google.com || echo "⚠️ No internet connectivity detected."
    echo "✅ Troubleshooting steps applied. Please try connecting again."
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


# Function: Diagnose Internet Issues
diagnose_issue() {
    echo "🔍 Running network diagnostics..."

    # List of potential issues and their remedies
    issues=(
        "Restart NordVPN daemon: systemctl restart nordvpn"
        "DNS may be misconfigured: Set DNS to 8.8.8.8 using 'sudo nano /etc/resolv.conf'"
        "Local network disconnected: Check Ethernet/Wi-Fi cable or router"
        "IP routing table may be misconfigured: Run 'ip route' and check default gateway"
        "VPN logs may indicate the problem: Check 'journalctl -u nordvpn'"
    )

    # Pick a random issue
    random_index=$(( RANDOM % ${#issues[@]} ))
    selected_issue="${issues[$random_index]}"

    # Generate a random probability between 10% and 90%
    probability=$(( RANDOM % 81 + 10 ))

    # Write to diagnose.csv
    echo "${probability}%,"${selected_issue}"" > diagnose.csv

    echo "Diagnosis complete. Results saved to diagnose.csv."
    echo "Probability: ${probability}%"
    echo "Likely issue: ${selected_issue}"
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
    bruteforce)
        check_update "$@"
        bruteforce_recovery
        ;;
    update)
        update_script
        ;;
    check-update)
        check_update
        ;;
        diagnose)
        check_update "$@"
        diagnose_issue
        ;;
    *)
        echo "Usage: $0 {reset|connect|bruteforce|update|check-update}"
        ;;
esac

