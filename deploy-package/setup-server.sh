#!/bin/bash
echo "🚀 Setting up OMEGA website on server..."

# Update system
apt update && apt upgrade -y

# Install nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo "📦 Installing Nginx..."
    apt install nginx -y
    systemctl enable nginx
fi

# Create website directory
mkdir -p /var/www/omega
chown -R www-data:www-data /var/www/omega

# Copy nginx configuration
cp omega-nginx.conf /etc/nginx/sites-available/omega
ln -sf /etc/nginx/sites-available/omega /etc/nginx/sites-enabled/omega

# Remove default nginx site
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
nginx -t

# Restart nginx
systemctl restart nginx
systemctl status nginx

echo "✅ OMEGA website deployed successfully!"
echo "🌐 Website should be accessible at: http://www.omegalang.xyz"
echo "📝 Don't forget to configure DNS A record: www.omegalang.xyz -> 103.27.206.177"
