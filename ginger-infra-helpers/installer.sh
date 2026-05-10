#!/bin/bash

# ── Root check ────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo"
    exit 1
fi

# ── OS guard ──────────────────────────────────────────────────────────────────
OS_TYPE=""
case "$(uname -s)" in
    Linux)
        OS_TYPE="linux"
        ;;
    Darwin)
        OS_TYPE="darwin"
        ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        echo "❌ Windows is not supported. Exiting."
        exit 1
        ;;
    *)
        echo "❌ Unsupported OS. Exiting."
        exit 1
        ;;
esac

# ── Argument parsing ──────────────────────────────────────────────────────────
DEVICE_ID=""
INSTALL_GATEWAY=false

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --device-id)
            DEVICE_ID="$2"
            shift 2
            ;;
        --install-gateway)
            INSTALL_GATEWAY=true
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: curl -fsSL <url> | bash -s -- --device-id <device-id> [--install-gateway]"
            exit 1
            ;;
    esac
done

if [ -z "$DEVICE_ID" ]; then
    echo "Usage: curl -fsSL <url> | bash -s -- --device-id <device-id> [--install-gateway]"
    echo "Example: curl -fsSL <url> | bash -s -- --device-id my-server --install-gateway"
    exit 1
fi

# ── Gateway on macOS guard ────────────────────────────────────────────────────
if [ "$INSTALL_GATEWAY" = true ] && [ "$OS_TYPE" = "darwin" ]; then
    echo "❌ --install-gateway is only supported on Linux."
    exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
is_installed() {
    command -v "$1" &>/dev/null
}

apt_install_if_missing() {
    local pkg="$1"
    local cmd="${2:-$1}"
    if is_installed "$cmd"; then
        echo "✅ $pkg already installed, skipping."
    else
        echo "📦 Installing $pkg..."
        apt-get install -y "$pkg"
        echo "✅ $pkg installed."
    fi
}

confirm() {
    read -r -p "$1 [y/N] " response </dev/tty
    [[ "$response" =~ ^[Yy]$ ]]
}

# ── Install ginger-infra binary ───────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Installing ginger-infra"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

bash -c "$(curl -fsSL https://raw.githubusercontent.com/ginger-society/infra-as-code-repo/main/rust-helpers/installer.sh)" -- ginger-society/ginger-infra:latest

if [ $? -ne 0 ]; then
    echo "❌ Failed to install ginger-infra"
    exit 1
fi

BINARY="/usr/local/bin/ginger-infra"
CONFIG_DIR="/etc/ginger-infra"
mkdir -p "$CONFIG_DIR"

# ── Set up daemon ─────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Setting up daemon"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$OS_TYPE" = "darwin" ]; then
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
    echo "   Device ID: ${DEVICE_ID}"
    echo "   Logs:      /var/log/ginger-infra.log"
    echo "   To stop:   sudo launchctl unload $PLIST"
    echo "   To start:  sudo launchctl load $PLIST"

elif [ "$OS_TYPE" = "linux" ]; then
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
    echo "   Device ID: ${DEVICE_ID}"
    echo "   Logs:      sudo journalctl -u ginger-infra -f"
    echo "   To stop:   sudo systemctl stop ginger-infra"
    echo "   To start:  sudo systemctl start ginger-infra"
    echo "   Status:    sudo systemctl status ginger-infra"
fi

# ── Gateway installation ──────────────────────────────────────────────────────
if [ "$INSTALL_GATEWAY" = false ]; then
    echo ""
    echo "✅ Done. Run with --install-gateway to also set up Apache2, Snap, Certbot and Nginx."
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Gateway Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will install and configure the following:"
echo "  • Snap"
echo "  • Certbot (via Snap)"
echo "  • Apache2 with modules: ssl, proxy, proxy_http, proxy_wstunnel, rewrite, headers"
echo "  • Nginx (configured to NOT listen on 80/443 — Apache2 is the main gateway)"
echo ""

if ! confirm "Proceed with gateway installation?"; then
    echo "Skipping gateway installation."
    exit 0
fi

apt-get update -y

# ── Snap ──────────────────────────────────────────────────────────────────────
echo ""
echo "── Snap ─────────────────────────────────────────────────"
apt_install_if_missing "snapd" "snap"

systemctl enable --now snapd.socket

# ensure snap core is up to date
snap install core 2>/dev/null
snap refresh core 2>/dev/null

# ── Certbot ───────────────────────────────────────────────────────────────────
echo ""
echo "── Certbot ──────────────────────────────────────────────"
if snap list certbot &>/dev/null; then
    echo "✅ certbot already installed via snap, skipping."
else
    echo "📦 Installing certbot via snap..."
    snap install --classic certbot
    ln -sf /snap/bin/certbot /usr/bin/certbot
    echo "✅ certbot installed."
fi

# ── Apache2 ───────────────────────────────────────────────────────────────────
echo ""
echo "── Apache2 ──────────────────────────────────────────────"
apt_install_if_missing "apache2" "apache2"

echo "🔧 Enabling Apache2 modules..."

APACHE_MODULES=(
    ssl
    proxy
    proxy_http
    proxy_wstunnel
    rewrite
    headers
)

for mod in "${APACHE_MODULES[@]}"; do
    if apache2ctl -M 2>/dev/null | grep -q "${mod}_module"; then
        echo "✅ mod_${mod} already enabled, skipping."
    else
        echo "  enabling mod_${mod}..."
        a2enmod "$mod"
    fi
done

# ── Nginx ─────────────────────────────────────────────────────────────────────
echo ""
echo "── Nginx ────────────────────────────────────────────────"
apt_install_if_missing "nginx" "nginx"

echo "🔧 Configuring Nginx to not listen on 80/443 (Apache2 is the gateway)..."

NGINX_DEFAULT="/etc/nginx/sites-enabled/default"

# disable the default site if present
if [ -f "$NGINX_DEFAULT" ]; then
    rm -f "$NGINX_DEFAULT"
    echo "   removed default nginx site"
fi

# write a safe fallback config that doesn't bind 80/443
cat > /etc/nginx/sites-available/ginger-infra-passthrough <<'EOF'
# Nginx managed by ginger-infra installer
# Apache2 handles 80 and 443 — Nginx is available for internal use only
# Add your internal upstreams here if needed
EOF

echo "✅ Nginx configured — not binding on 80/443."

# ── Restart services ──────────────────────────────────────────────────────────
echo ""
echo "── Restarting services ──────────────────────────────────"

systemctl restart apache2
if [ $? -eq 0 ]; then
    echo "✅ Apache2 restarted."
else
    echo "⚠️  Apache2 failed to restart — check: sudo journalctl -u apache2"
fi

systemctl restart nginx
if [ $? -eq 0 ]; then
    echo "✅ Nginx restarted."
else
    echo "⚠️  Nginx failed to restart — check: sudo journalctl -u nginx"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Gateway installation complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Add your VirtualHost configs to /etc/apache2/sites-available/"
echo "  2. Enable them with:  sudo a2ensite <your-site>.conf"
echo "  3. Get SSL certs:     sudo certbot --apache -d yourdomain.com"
echo "  4. Reload Apache2:    sudo systemctl reload apache2"
echo ""
echo "  ginger-infra logs:  sudo journalctl -u ginger-infra -f"
echo "  Apache2 logs:       /var/log/apache2/"