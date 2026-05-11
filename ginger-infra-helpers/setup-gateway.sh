#!/bin/bash

# ── Root check ────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo"
    exit 1
fi

# ── Argument parsing ──────────────────────────────────────────────────────────
DOMAIN=""
HTTP_PORT=""
WEBSOCKET=false

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --port)
            HTTP_PORT="$2"
            shift 2
            ;;
        --websocket)
            WEBSOCKET=true
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 --domain <domain> --port <http-port> [--websocket]"
            exit 1
            ;;
    esac
done

# ── Interactive prompts for missing args ──────────────────────────────────────
if [ -z "$DOMAIN" ]; then
    read -r -p "Enter the domain name (e.g. api.gingersociety.org): " DOMAIN </dev/tty
fi

if [ -z "$DOMAIN" ]; then
    echo "❌ Domain is required."
    exit 1
fi

if [ -z "$HTTP_PORT" ]; then
    read -r -p "Enter the backend HTTP port (e.g. 8081): " HTTP_PORT </dev/tty
fi

if [ -z "$HTTP_PORT" ]; then
    echo "❌ HTTP port is required."
    exit 1
fi

if ! [[ "$HTTP_PORT" =~ ^[0-9]+$ ]] || [ "$HTTP_PORT" -lt 1 ] || [ "$HTTP_PORT" -gt 65535 ]; then
    echo "❌ Invalid port: $HTTP_PORT"
    exit 1
fi

if [ "$WEBSOCKET" = false ]; then
    read -r -p "Enable WebSocket support? [y/N] " ws_response </dev/tty
    [[ "$ws_response" =~ ^[Yy]$ ]] && WEBSOCKET=true
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Gateway Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Domain:    $DOMAIN"
echo "  Port:      $HTTP_PORT"
echo "  WebSocket: $WEBSOCKET"
echo ""

# ── SSL check ─────────────────────────────────────────────────────────────────
SSL_CERT="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
SSL_KEY="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
SSL_OPTIONS="/etc/letsencrypt/options-ssl-apache.conf"

SSL_AVAILABLE=false
if [ -f "$SSL_CERT" ] && [ -f "$SSL_KEY" ]; then
    SSL_AVAILABLE=true
    echo "✅ SSL certificates found for $DOMAIN"
else
    echo "⚠️  SSL certificates NOT found at /etc/letsencrypt/live/${DOMAIN}/"
    echo "   The config will be written with HTTP only."
    echo "   Run: sudo certbot certonly --apache -d ${DOMAIN}"
    echo "   Then re-run this script to enable HTTPS."
fi

# ── Ensure log directory exists ───────────────────────────────────────────────
LOG_DIR="/var/log/apache2/gingersociety"
if [ ! -d "$LOG_DIR" ]; then
    echo "📁 Creating log directory: $LOG_DIR"
    mkdir -p "$LOG_DIR"
    echo "✅ Log directory created."
else
    echo "✅ Log directory already exists."
fi

# ── Ensure sites-available/gingersociety dir and apache2.conf include ─────────
SITES_AVAILABLE="/etc/apache2/sites-available"
CONF_FILE="${SITES_AVAILABLE}/${DOMAIN}.conf"
APACHE_CONF="/etc/apache2/apache2.conf"
SITES_ENABLED="/etc/apache2/sites-enabled"

# Check that apache2 is installed
if ! command -v apache2ctl &>/dev/null; then
    echo "❌ Apache2 is not installed. Please install it first."
    exit 1
fi

# Ensure IncludeOptional sites-enabled is present in apache2.conf
if ! grep -q "sites-enabled" "$APACHE_CONF"; then
    echo "🔧 Adding IncludeOptional sites-enabled/*.conf to apache2.conf..."
    echo "IncludeOptional sites-enabled/*.conf" >> "$APACHE_CONF"
    echo "✅ apache2.conf updated."
else
    echo "✅ apache2.conf already includes sites-enabled."
fi

# ── Build WebSocket block ─────────────────────────────────────────────────────
if [ "$WEBSOCKET" = true ]; then
    WS_BLOCK="
    # WebSocket Proxy
    ProxyPass /notification/ws/ ws://0.0.0.0:${HTTP_PORT}/notification/ws/
    ProxyPassReverse /notification/ws/ ws://0.0.0.0:${HTTP_PORT}/notification/ws/

    # Enable WebSocket Upgrade Handling
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/notification/ws/(.*) ws://0.0.0.0:${HTTP_PORT}/notification/ws/\$1 [P,L]"
else
    WS_BLOCK="
    RewriteEngine On"
fi

# ── Write the config file ─────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Writing Apache2 config: $CONF_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$SSL_AVAILABLE" = true ]; then
    cat > "$CONF_FILE" <<EOF
<VirtualHost *:80>
    ServerName ${DOMAIN}
    ErrorLog \${APACHE_LOG_DIR}/gingersociety/${DOMAIN//./_}_error.log
    CustomLog \${APACHE_LOG_DIR}/gingersociety/${DOMAIN//./_}_access.log combined

    RewriteEngine on
    RewriteCond %{SERVER_NAME} =${DOMAIN}
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName ${DOMAIN}

    ProxyPreserveHost On

    # Remove POST body size limit
    LimitRequestBody 0

    # Setup the proxy
    <Proxy *>
        Require all granted
    </Proxy>

    # Standard HTTP Proxy
    ProxyPass "/" "http://0.0.0.0:${HTTP_PORT}/"
    ProxyPassReverse "/" "http://0.0.0.0:${HTTP_PORT}/"
${WS_BLOCK}

    ErrorLog \${APACHE_LOG_DIR}/gingersociety/${DOMAIN//./_}_error.log
    CustomLog \${APACHE_LOG_DIR}/gingersociety/${DOMAIN//./_}_access.log combined

    SSLCertificateFile /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/${DOMAIN}/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
</IfModule>
EOF
else
    # HTTP only — no SSL yet
    cat > "$CONF_FILE" <<EOF
<VirtualHost *:80>
    ServerName ${DOMAIN}

    ProxyPreserveHost On

    # Remove POST body size limit
    LimitRequestBody 0

    # Setup the proxy
    <Proxy *>
        Require all granted
    </Proxy>

    # Standard HTTP Proxy
    ProxyPass "/" "http://0.0.0.0:${HTTP_PORT}/"
    ProxyPassReverse "/" "http://0.0.0.0:${HTTP_PORT}/"
${WS_BLOCK}

    ErrorLog \${APACHE_LOG_DIR}/gingersociety/${DOMAIN//./_}_error.log
    CustomLog \${APACHE_LOG_DIR}/gingersociety/${DOMAIN//./_}_access.log combined
</VirtualHost>
EOF
fi

echo "✅ Config written to $CONF_FILE"

# ── Enable the site ───────────────────────────────────────────────────────────
ENABLED_LINK="${SITES_ENABLED}/${DOMAIN}.conf"
if [ ! -L "$ENABLED_LINK" ]; then
    echo "🔗 Enabling site..."
    a2ensite "${DOMAIN}.conf"
else
    echo "✅ Site already enabled."
fi

# ── Test Apache config ────────────────────────────────────────────────────────
echo ""
echo "🔍 Testing Apache2 configuration..."
if apache2ctl configtest 2>&1; then
    echo "✅ Apache2 config test passed."
else
    echo "❌ Apache2 config test failed. Fix the errors above before restarting."
    exit 1
fi

# ── Restart Apache2 ───────────────────────────────────────────────────────────
echo ""
echo "🔄 Restarting Apache2..."
if systemctl restart apache2; then
    echo "✅ Apache2 restarted successfully."
else
    echo "❌ Apache2 failed to restart."
    echo "   Check: sudo journalctl -u apache2 -n 50"
    exit 1
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Gateway setup complete for ${DOMAIN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Config file:  $CONF_FILE"
echo "  Backend port: $HTTP_PORT"
echo "  WebSocket:    $WEBSOCKET"
if [ "$SSL_AVAILABLE" = true ]; then
    echo "  SSL:          ✅ Enabled"
else
    echo "  SSL:          ⚠️  Not yet — run certbot then re-run this script"
    echo "  Certbot cmd:  sudo certbot certonly --apache -d ${DOMAIN}"
fi
echo ""
echo "  Logs:         $LOG_DIR/"
echo "  Apache status: sudo systemctl status apache2"