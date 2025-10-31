# OMEGA Website Deployment Script
# Note: Do NOT hardcode secrets. Use environment variables (OMEGA_SERVER_IP, OMEGA_SERVER_USER, OMEGA_SERVER_DOMAIN)

param(
    [string]$ServerIP = $env:OMEGA_SERVER_IP,
    [string]$Username = $env:OMEGA_SERVER_USER,
    [string]$Domain = $env:OMEGA_SERVER_DOMAIN
)

if (-not $ServerIP -or -not $Domain) {
    Write-Host "ℹ️ ServerIP/Domain not provided; package will include placeholders. Set OMEGA_SERVER_IP and OMEGA_SERVER_DOMAIN if available." -ForegroundColor Yellow
}

Write-Host "🚀 OMEGA Website Deployment Script" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check if website directory exists
if (-not (Test-Path "website")) {
    Write-Host "❌ Website directory not found!" -ForegroundColor Red
    exit 1
}

Write-Host "📁 Website files found in ./website/" -ForegroundColor Green

# Create deployment package
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
$deployDir = "deploy-package"
if (Test-Path $deployDir) {
    Remove-Item $deployDir -Recurse -Force
}
New-Item -ItemType Directory -Path $deployDir | Out-Null

# Copy website files
Copy-Item "website\*" $deployDir -Recurse -Force
Write-Host "✅ Website files copied to deployment package" -ForegroundColor Green

# Create nginx configuration
$nginxConfig = @"
server {
    listen 80;
    server_name $Domain;
    root /var/www/omega;
    index index.html;

    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Cache static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Main location
    location / {
        try_files `$uri `$uri/ /index.html;
    }

    # Playground specific
    location /playground.html {
        try_files `$uri =404;
    }

    # Examples specific
    location /examples.html {
        try_files `$uri =404;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
"@

$nginxConfig | Out-File -FilePath "$deployDir\omega-nginx.conf" -Encoding UTF8
Write-Host "✅ Nginx configuration created" -ForegroundColor Green

# Create deployment script for server
$serverScript = @"
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
echo "🌐 Website should be accessible at: http://$Domain"
echo "📝 Don't forget to configure DNS A record: $Domain -> $ServerIP"
"@

$serverScript | Out-File -FilePath "$deployDir\setup-server.sh" -Encoding UTF8
Write-Host "✅ Server setup script created" -ForegroundColor Green

Write-Host "`n📋 Deployment package ready in ./$deployDir/" -ForegroundColor Cyan
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Upload files to server via SCP/SFTP" -ForegroundColor White
Write-Host "   2. Run setup-server.sh on the server" -ForegroundColor White
Write-Host "   3. Configure DNS A record" -ForegroundColor White
Write-Host "   4. Test the website" -ForegroundColor White

Write-Host "`n🔐 Server Details:" -ForegroundColor Cyan
Write-Host "   IP: $ServerIP" -ForegroundColor White
Write-Host "   Username: $Username" -ForegroundColor White
Write-Host "   Domain: $Domain" -ForegroundColor White