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

# ── Device ID argument ────────────────────────────────────────────────────────
if [ "$#" -ne 1 ]; then
    echo "Usage: sudo $0 <device-id>"
    echo "Example: sudo $0 my-macbook"
    exit 1
fi

DEVICE_ID="$1"

# ── Install the binary first ──────────────────────────────────────────────────
echo "Installing ginger-infra..."
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ginger-society/infra-as-code-repo/main/rust-helpers/installer.sh)" -- ginger-society/ginger-infra:latest

if [ $? -ne 0 ]; then
    echo "Failed to install ginger-infra"
    exit 1
fi

BINARY="/usr/local/bin/ginger-infra"
CONFIG_DIR="/etc/ginger-infra"

# ── Create config dir ─────────────────────────────────────────────────────────
mkdir -p "$CONFIG_DIR"

# ── Detect OS and set up daemon ───────────────────────────────────────────────
case "$(uname -s)" in

    Darwin)
        # ── macOS — launchd ───────────────────────────────────────────────────
        PLIST="/Library/LaunchDaemons/org.gingersociety.ginger-infra.plist"

        cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.gingersociety.ginger-infra</string>

    <key>ProgramArguments</key>
    <array>
        <string>${BINARY}</string>
        <string>start</string>
        <string>--device-id</string>
        <string>${DEVICE_ID}</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/var/log/ginger-infra.log</string>

    <key>StandardErrorPath</key>
    <string>/var/log/ginger-infra.error.log</string>

    <key>WorkingDirectory</key>
    <string>/etc/ginger-infra</string>
</dict>
</plist>
EOF

        chown root:wheel "$PLIST"
        chmod 644 "$PLIST"

        launchctl unload "$PLIST" 2>/dev/null
        launchctl load -w "$PLIST"

        echo "✅ ginger-infra daemon installed and started via launchd"
        echo "   Device ID:  ${DEVICE_ID}"
        echo "   Logs:       /var/log/ginger-infra.log"
        echo "   To stop:    sudo launchctl unload $PLIST"
        echo "   To start:   sudo launchctl load $PLIST"
        ;;

    Linux)
        # ── Linux — systemd ───────────────────────────────────────────────────
        SERVICE="/etc/systemd/system/ginger-infra.service"

        cat > "$SERVICE" <<EOF
[Unit]
Description=Ginger Infra Daemon
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${BINARY} start --device-id ${DEVICE_ID}
Restart=always
RestartSec=5
WorkingDirectory=/etc/ginger-infra
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ginger-infra

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable ginger-infra
        systemctl restart ginger-infra

        echo "✅ ginger-infra daemon installed and started via systemd"
        echo "   Device ID:  ${DEVICE_ID}"
        echo "   Logs:       sudo journalctl -u ginger-infra -f"
        echo "   To stop:    sudo systemctl stop ginger-infra"
        echo "   To start:   sudo systemctl start ginger-infra"
        echo "   Status:     sudo systemctl status ginger-infra"
        ;;

    *)
        echo "Unsupported OS"
        exit 1
        ;;
esac