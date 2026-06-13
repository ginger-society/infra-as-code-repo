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

# ── Derive SSL_BASE_DOMAIN from DOMAIN ───────────────────────────────────────
# e.g. dev-portal.feat-18.ginger-society.test-clusters.rackmint.com
#   -> feat-18.ginger-society.test-clusters.rackmint.com
SSL_BASE_DOMAIN="${DOMAIN#*.}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Gateway Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Domain:          $DOMAIN"
echo "  Port:            $HTTP_PORT"
echo "  WebSocket:       $WEBSOCKET"
echo "  SSL base domain: $SSL_BASE_DOMAIN"
echo ""

# ── SSL check — prefer wildcard cert at base domain, fall back to exact ───────
SSL_CERT=""
SSL_KEY=""
SSL_AVAILABLE=false

WILDCARD_CERT="/etc/letsencrypt/live/${SSL_BASE_DOMAIN}/fullchain.pem"
WILDCARD_KEY="/etc/letsencrypt/live/${SSL_BASE_DOMAIN}/privkey.pem"
EXACT_CERT="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
EXACT_KEY="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"

if [ -f "$WILDCARD_CERT" ] && [ -f "$WILDCARD_KEY" ]; then
    SSL_CERT="$WILDCARD_CERT"
    SSL_KEY="$WILDCARD_KEY"
    SSL_AVAILABLE=true
    echo "✅ Wildcard SSL cert found at /etc/letsencrypt/live/${SSL_BASE_DOMAIN}/"
elif [ -f "$EXACT_CERT" ] && [ -f "$EXACT_KEY" ]; then
    SSL_CERT="$EXACT_CERT"
    SSL_KEY="$EXACT_KEY"
    SSL_AVAILABLE=true
    echo "✅ Exact SSL cert found at /etc/letsencrypt/live/${DOMAIN}/"
else
    echo "⚠️  SSL certificates NOT found at either:"
    echo "     /etc/letsencrypt/live/${SSL_BASE_DOMAIN}/ (wildcard)"
    echo "     /etc/letsencrypt/live/${DOMAIN}/ (exact)"
    echo "   The config will be written with HTTP only."
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

# ── Ensure sites-available and apache2.conf include ───────────────────────────
SITES_AVAILABLE="/etc/apache2/sites-available"
CONF_FILE="${SITES_AVAILABLE}/${DOMAIN}.conf"
APACHE_CONF="/etc/apache2/apache2.conf"
SITES_ENABLED="/etc/apache2/sites-enabled"

if ! command -v apache2ctl &>/dev/null; then
    echo "❌ Apache2 is not installed. Please install it first."
    exit 1
fi

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
    # WebSocket — global upgrade handling (must be before ProxyPass)
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/(.*) ws://0.0.0.0:${HTTP_PORT}/\$1 [P,L]"
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
    LimitRequestBody 0

    <Proxy *>
        Require all granted
    </Proxy>
${WS_BLOCK}

    ProxyPass "/" "http://0.0.0.0:${HTTP_PORT}/"
    ProxyPassReverse "/" "http://0.0.0.0:${HTTP_PORT}/"

    ErrorLog \${APACHE_LOG_DIR}/gingersociety/${DOMAIN//./_}_error.log
    CustomLog \${APACHE_LOG_DIR}/gingersociety/${DOMAIN//./_}_access.log combined

    SSLCertificateFile ${SSL_CERT}
    SSLCertificateKeyFile ${SSL_KEY}
    Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost>
</IfModule>
EOF
else
    cat > "$CONF_FILE" <<EOF
<VirtualHost *:80>
    ServerName ${DOMAIN}

    ProxyPreserveHost On
    LimitRequestBody 0

    <Proxy *>
        Require all granted
    </Proxy>
${WS_BLOCK}

    ProxyPass "/" "http://0.0.0.0:${HTTP_PORT}/"
    ProxyPassReverse "/" "http://0.0.0.0:${HTTP_PORT}/"

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
if systemctl reload apache2; then
    echo "✅ Apache2 reloaded successfully."
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
echo "  Config file:   $CONF_FILE"
echo "  Backend port:  $HTTP_PORT"
echo "  WebSocket:     $WEBSOCKET"
echo "  SSL cert:      ${SSL_CERT:-none}"
echo ""
echo "  Logs:          $LOG_DIR/"
echo "  Apache status: sudo systemctl status apache2"