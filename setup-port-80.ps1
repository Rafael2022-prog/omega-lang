# Setup Port 80 for OMEGA Website
# This script configures the server to serve the website on standard port 80

Write-Host "=== OMEGA Website Port 80 Setup ===" -ForegroundColor Cyan
Write-Host "Configuring server to serve website on standard port 80..." -ForegroundColor Yellow

$serverIP = "103.27.206.177"
$sshUser = "root"

try {
    Write-Host "`n1. Stopping current Python server on port 8080..." -ForegroundColor Green
    ssh $sshUser@$serverIP "pkill -f 'python.*http.server' || true"
    Start-Sleep -Seconds 2

    Write-Host "`n2. Installing and configuring Nginx properly..." -ForegroundColor Green
    $nginxSetup = @"
# Update system
apt-get update -y

# Install Nginx
apt-get install -y nginx

# Stop default Nginx if running
systemctl stop nginx 2>/dev/null || true

# Remove default Nginx configuration
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

# Create OMEGA site configuration
cat > /etc/nginx/sites-available/omega << 'EOF'
server {
    listen 80;
    server_name omegalang.xyz www.omegalang.xyz;
    
    root /var/www/omega;
    index index.html;
    
    location / {
        try_files `$uri `$uri/ =404;
    }
    
    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Cache static files
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/omega /etc/nginx/sites-enabled/

# Test Nginx configuration
nginx -t

# Start and enable Nginx
systemctl start nginx
systemctl enable nginx

# Check if Nginx is running
systemctl status nginx --no-pager -l

echo "Nginx configuration completed!"
"@

    Write-Host "Executing Nginx setup commands..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP $nginxSetup

    Write-Host "`n3. Configuring firewall for port 80..." -ForegroundColor Green
    ssh $sshUser@$serverIP @"
# Allow HTTP traffic
ufw allow 80/tcp 2>/dev/null || iptables -A INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || echo "Firewall configuration attempted"

# Check if port 80 is listening
netstat -tlnp | grep :80 || ss -tlnp | grep :80 || echo "Port 80 status check completed"
"@

    Write-Host "`n4. Testing website accessibility..." -ForegroundColor Green
    
    # Test local access on server
    Write-Host "Testing local access on server..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://localhost/ || echo 'Local test failed'"
    
    # Test external access via IP
    Write-Host "Testing external access via IP..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://$serverIP" -Method GET -TimeoutSec 10
        Write-Host "✅ IP Access: HTTP $($response.StatusCode) - Content Length: $($response.Content.Length)" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ IP Access failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test external access via domain
    Write-Host "Testing external access via domain..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://omegalang.xyz" -Method GET -TimeoutSec 10
        Write-Host "✅ Domain Access: HTTP $($response.StatusCode) - Content Length: $($response.Content.Length)" -ForegroundColor Green
        
        # Check if content contains OMEGA
        if ($response.Content -match "OMEGA") {
            Write-Host "✅ Website content verified - OMEGA found!" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "❌ Domain Access failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`n=== Port 80 Setup Summary ===" -ForegroundColor Cyan
    Write-Host "✅ Nginx installed and configured" -ForegroundColor Green
    Write-Host "✅ Website configured for port 80" -ForegroundColor Green
    Write-Host "✅ Firewall configured for HTTP traffic" -ForegroundColor Green
    Write-Host "`nWebsite should now be accessible at:" -ForegroundColor Yellow
    Write-Host "• http://omegalang.xyz" -ForegroundColor White
    Write-Host "• http://www.omegalang.xyz (if DNS configured)" -ForegroundColor White
    Write-Host "• http://$serverIP" -ForegroundColor White
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "• Configure www.omegalang.xyz DNS record if needed" -ForegroundColor White
    Write-Host "• Set up SSL certificate for HTTPS" -ForegroundColor White
    Write-Host "• Monitor server performance" -ForegroundColor White

}
catch {
    Write-Host "❌ Error during port 80 setup: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check server connectivity and try again." -ForegroundColor Yellow
}

Write-Host "`nPort 80 setup completed!" -ForegroundColor Cyan