#!/bin/bash

# ── Root check ────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo"
    exit 1
fi

# ── Argument parsing ──────────────────────────────────────────────────────────
DOMAIN=""

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 --domain <domain>"
            exit 1
            ;;
    esac
done

if [ -z "$DOMAIN" ]; then
    read -r -p "Enter the domain name to remove: " DOMAIN </dev/tty
fi

if [ -z "$DOMAIN" ]; then
    echo "❌ Domain is required."
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Deleting Gateway for: $DOMAIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SITES_AVAILABLE="/etc/apache2/sites-available"
SITES_ENABLED="/etc/apache2/sites-enabled"
CONF_FILE="${SITES_AVAILABLE}/${DOMAIN}.conf"
ENABLED_LINK="${SITES_ENABLED}/${DOMAIN}.conf"

# ── Disable the site ──────────────────────────────────────────────────────────
if [ -L "$ENABLED_LINK" ]; then
    echo "🔗 Disabling site..."
    a2dissite "${DOMAIN}.conf"
    echo "✅ Site disabled."
else
    echo "⚠️  Site was not enabled, skipping a2dissite."
fi

# ── Remove the config file ────────────────────────────────────────────────────
if [ -f "$CONF_FILE" ]; then
    echo "🗑️  Removing config file: $CONF_FILE"
    rm -f "$CONF_FILE"
    echo "✅ Config file removed."
else
    echo "⚠️  Config file not found: $CONF_FILE"
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
echo "✅ Gateway deleted for ${DOMAIN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Removed:  $CONF_FILE"
echo "  Note: SSL certificates in /etc/letsencrypt/live/${DOMAIN}/ were NOT removed."
echo "        To also remove them run: sudo certbot delete --cert-name ${DOMAIN}"
echo ""