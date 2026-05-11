#!/bin/bash

# ── Root check ────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo"
    exit 1
fi

# ── Windows guard ─────────────────────────────────────────────────────────────
case "$(uname -s)" in
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        echo "Windows is not supported. Exiting."
        exit 1
        ;;
esac

BINARY="/usr/local/bin/ginger-infra"
CONFIG_DIR="/etc/ginger-infra"

# ── Detect OS and tear down daemon ───────────────────────────────────────────
case "$(uname -s)" in

    Darwin)
        PLIST="/Library/LaunchDaemons/org.gingersociety.ginger-infra.plist"

        if [ -f "$PLIST" ]; then
            echo "Stopping and unloading launchd daemon..."
            launchctl unload -w "$PLIST" 2>/dev/null
            rm -f "$PLIST"
            echo "Removed $PLIST"
        else
            echo "No launchd plist found, skipping..."
        fi
        ;;

    Linux)
        if systemctl is-active --quiet ginger-infra 2>/dev/null; then
            echo "Stopping ginger-infra service..."
            systemctl stop ginger-infra
        fi

        if systemctl is-enabled --quiet ginger-infra 2>/dev/null; then
            echo "Disabling ginger-infra service..."
            systemctl disable ginger-infra
        fi

        SERVICE="/etc/systemd/system/ginger-infra.service"
        if [ -f "$SERVICE" ]; then
            rm -f "$SERVICE"
            echo "Removed $SERVICE"
            systemctl daemon-reload
        else
            echo "No systemd service file found, skipping..."
        fi
        ;;

    *)
        echo "Unsupported OS"
        exit 1
        ;;
esac

# ── Remove binary ─────────────────────────────────────────────────────────────
if [ -f "$BINARY" ]; then
    rm -f "$BINARY"
    echo "Removed $BINARY"
else
    echo "Binary not found at $BINARY, skipping..."
fi

# ── Remove config dir (prompt first) ─────────────────────────────────────────
if [ -d "$CONFIG_DIR" ]; then
    read -r -p "Remove config directory $CONFIG_DIR? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        echo "Removed $CONFIG_DIR"
    else
        echo "Keeping $CONFIG_DIR"
    fi
fi

# ── Remove logs ───────────────────────────────────────────────────────────────
if [ -f "/var/log/ginger-infra.log" ] || [ -f "/var/log/ginger-infra.error.log" ]; then
    read -r -p "Remove log files? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -f /var/log/ginger-infra.log /var/log/ginger-infra.error.log
        echo "Removed log files"
    else
        echo "Keeping log files"
    fi
fi

echo ""
echo "✅ ginger-infra uninstalled successfully"
echo "Please note that we only removed ginger society's infra helpers. If you have other tools installed such as docker , kubectl , kind, they will not be affected."