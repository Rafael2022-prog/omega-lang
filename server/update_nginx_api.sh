#!/bin/bash
# Update nginx to proxy API requests

CONFIG=/etc/nginx/conf.d/omega.conf

# Backup
cp $CONFIG ${CONFIG}.before_api

# Create new config with API proxy
cat > $CONFIG << 'NGINXCONF'
# OMEGA API upstream
upstream omega_api {
    server 127.0.0.1:3000;
    keepalive 32;
}

server {
    server_name omegalang.xyz www.omegalang.xyz;

    root /var/www/omega;
    index index.html;

    # API endpoints - proxy to Node.js
    location /api/ {
        proxy_pass http://omega_api/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "https://omegalang.xyz" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        
        if ($request_method = OPTIONS) {
            return 204;
        }
    }

    # Static files
    location / {
        try_files $uri $uri/ $uri.html =404;
    }

    location ~ /\.ht {
        deny all;
    }

    # SSL
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/omegalang.xyz/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/omegalang.xyz/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    listen 80;
    server_name omegalang.xyz www.omegalang.xyz;
    return 301 https://$host$request_uri;
}
NGINXCONF

# Test and reload
nginx -t && systemctl reload nginx && echo 'Nginx updated successfully!'

# Test API through nginx
echo ""
echo "Testing API through nginx..."
curl -s https://omegalang.xyz/api/health
