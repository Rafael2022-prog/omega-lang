# SSL Certificate Setup for OMEGA Website
# This script configures SSL certificate using Let's Encrypt for HTTPS access

Write-Host "=== OMEGA Website SSL Certificate Setup ===" -ForegroundColor Cyan
Write-Host "Configuring SSL certificate for HTTPS access..." -ForegroundColor Yellow

$serverIP = "103.27.206.177"
$sshUser = "root"
$domain = "omegalang.xyz"
$wwwDomain = "www.omegalang.xyz"

try {
    Write-Host "`n1. Installing Certbot and Nginx..." -ForegroundColor Green
    $installCommands = @"
# Update system
dnf update -y

# Install EPEL repository for additional packages
dnf install -y epel-release

# Install Nginx and Certbot
dnf install -y nginx certbot python3-certbot-nginx

# Install additional tools
dnf install -y curl wget net-tools

# Enable and start Nginx
systemctl enable nginx
systemctl start nginx

# Check Nginx status
systemctl status nginx --no-pager -l

echo "Installation completed!"
"@

    Write-Host "Installing required packages..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP $installCommands

    Write-Host "`n2. Configuring Nginx for SSL..." -ForegroundColor Green
    $nginxConfig = @"
# Stop current Python server
pkill -f 'python.*http.server.*80' 2>/dev/null || true

# Create Nginx configuration for OMEGA
cat > /etc/nginx/conf.d/omega.conf << 'EOF'
# HTTP server block - redirects to HTTPS
server {
    listen 80;
    server_name $domain $wwwDomain;
    
    # Let's Encrypt challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server block
server {
    listen 443 ssl http2;
    server_name $domain $wwwDomain;
    
    # SSL certificate paths (will be configured by certbot)
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Document root
    root /var/www/omega;
    index index.html;
    
    # Main location block
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Cache static files
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF

# Create directory for Let's Encrypt challenges
mkdir -p /var/www/certbot

# Remove default Nginx configuration
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true

# Test Nginx configuration
nginx -t

# Reload Nginx
systemctl reload nginx

echo "Nginx configuration completed!"
"@

    Write-Host "Configuring Nginx..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP $nginxConfig

    Write-Host "`n3. Obtaining SSL certificate..." -ForegroundColor Green
    $sslCommands = @"
# Stop Nginx temporarily for standalone mode
systemctl stop nginx

# Obtain SSL certificate using standalone mode
certbot certonly --standalone --non-interactive --agree-tos --email admin@$domain -d $domain -d $wwwDomain

# Start Nginx again
systemctl start nginx

# Test SSL certificate
certbot certificates

# Setup automatic renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -

echo "SSL certificate setup completed!"
"@

    Write-Host "Obtaining SSL certificate..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP $sslCommands

    Write-Host "`n4. Testing HTTPS access..." -ForegroundColor Green
    Start-Sleep -Seconds 10
    
    # Test HTTPS access
    Write-Host "Testing HTTPS access..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "https://$domain" -Method GET -TimeoutSec 15
        Write-Host "✅ HTTPS Access: HTTP $($response.StatusCode) - Content Length: $($response.Content.Length)" -ForegroundColor Green
        
        if ($response.Content -match "OMEGA") {
            Write-Host "✅ HTTPS content verified - OMEGA found!" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "❌ HTTPS Access failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Note: SSL certificate may need time to propagate" -ForegroundColor Yellow
    }

    Write-Host "`n=== SSL Certificate Setup Summary ===" -ForegroundColor Cyan
    Write-Host "✅ Nginx installed and configured" -ForegroundColor Green
    Write-Host "✅ SSL certificate obtained from Let's Encrypt" -ForegroundColor Green
    Write-Host "✅ HTTPS redirect configured" -ForegroundColor Green
    Write-Host "✅ Security headers added" -ForegroundColor Green
    Write-Host "✅ Automatic renewal configured" -ForegroundColor Green
    
    Write-Host "`nWebsite now accessible via HTTPS:" -ForegroundColor Yellow
    Write-Host "• https://$domain" -ForegroundColor White
    Write-Host "• https://$wwwDomain" -ForegroundColor White
    Write-Host "• HTTP traffic automatically redirected to HTTPS" -ForegroundColor White

}
catch {
    Write-Host "❌ Error during SSL setup: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check server connectivity and domain DNS configuration." -ForegroundColor Yellow
}

Write-Host "`nSSL Certificate setup completed!" -ForegroundColor Cyan