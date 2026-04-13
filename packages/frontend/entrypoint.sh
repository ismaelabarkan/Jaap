#!/bin/sh
set -e

# Default API URL - gebruik Azure internal URL als default
API_BACKEND_URL=${API_BACKEND_URL:-"http://jaapjunior-api.internal.bluerock-7a3df5c8.westeurope.azurecontainerapps.io"}

# Extract hostname from URL for Host header
# Remove protocol (http:// or https://), port number, and path
API_HOSTNAME=$(echo "$API_BACKEND_URL" | sed -e 's|^https\?://||' -e 's|:[0-9]*||' -e 's|/.*||')

# Auto-detect DNS resolver based on platform
# Azure: 168.63.129.16
# Railway/Docker: Use system resolver from /etc/resolv.conf
if [ -f "/etc/resolv.conf" ]; then
    SYSTEM_DNS=$(grep -m1 "^nameserver" /etc/resolv.conf | awk '{print $2}')
    if [ "$SYSTEM_DNS" = "168.63.129.16" ]; then
        # Azure detected
        DNS_RESOLVER="resolver 168.63.129.16 valid=10s;"
    elif [ -n "$SYSTEM_DNS" ]; then
        # Railway or other platform - check if IPv6
        if echo "$SYSTEM_DNS" | grep -q ':'; then
            # IPv6 address - needs brackets for Nginx
            DNS_RESOLVER="resolver [$SYSTEM_DNS] valid=10s;"
        else
            # IPv4 address
            DNS_RESOLVER="resolver $SYSTEM_DNS valid=10s;"
        fi
    else
        # Fallback: no explicit resolver (Nginx will use system default)
        DNS_RESOLVER="# No explicit resolver needed"
    fi
else
    DNS_RESOLVER="# No explicit resolver needed"
fi

echo "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo "  Jaap Junior Frontend - Starting"
echo "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo "API Backend URL: $API_BACKEND_URL"
echo "API Hostname: $API_HOSTNAME"
echo ""

# Vervang placeholders in template met echte waarden
echo "â†’ Configuring nginx with API backend..."
echo "â†’ DNS Resolver: $DNS_RESOLVER"

# Escape special characters for sed
DNS_RESOLVER_ESCAPED=$(echo "$DNS_RESOLVER" | sed 's/[&/\]/\\&/g')

sed -e "s|\${API_BACKEND_URL}|$API_BACKEND_URL|g" \
    -e "s|\${API_HOSTNAME}|$API_HOSTNAME|g" \
    -e "s|\${DNS_RESOLVER}|$DNS_RESOLVER_ESCAPED|g" \
    /etc/nginx/templates/nginx.conf.template > /etc/nginx/conf.d/default.conf

echo "âœ“ Nginx configured successfully"
echo ""

# Test nginx configuratie
echo "â†’ Testing nginx configuration..."
nginx -t

echo ""
echo "âœ“ Configuration valid"
echo ""
echo "â†’ Starting nginx..."
echo "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo ""

# Start nginx in foreground
exec nginx -g "daemon off;"
