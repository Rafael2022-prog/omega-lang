# Install and Configure Web Server for OMEGA Website
# Complete setup from scratch

param(
    [string]$ServerIP = "103.27.206.177",
    [string]$Username = "root", 
    [string]$Password = "!eL3H!Ue^Ik2"
)

Write-Host "🚀 OMEGA Web Server Installation" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Function to execute SSH command
function Invoke-SSHCommand {
    param([string]$Command)
    
    Write-Host "Executing: $Command" -ForegroundColor Gray
    $sshCmd = "plink -batch -pw `"$Password`" $Username@$ServerIP `"$Command`""
    
    try {
        $result = & cmd /c $sshCmd 2>&1
        if ($result) {
            Write-Host "  $result" -ForegroundColor DarkGray
        }
        return $true
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Step 1: Update system and install nginx
Write-Host "`n📦 Installing nginx..." -ForegroundColor Yellow
$installCommands = @(
    "apt update -y",
    "apt install -y nginx",
    "ufw allow 'Nginx Full'",
    "ufw allow ssh",
    "ufw --force enable"
)

foreach ($cmd in $installCommands) {
    Invoke-SSHCommand -Command $cmd
}

# Step 2: Start and enable nginx
Write-Host "`n🔄 Starting nginx service..." -ForegroundColor Yellow
Invoke-SSHCommand -Command "systemctl start nginx"
Invoke-SSHCommand -Command "systemctl enable nginx"
Invoke-SSHCommand -Command "systemctl status nginx --no-pager"

# Step 3: Create website directory and copy files
Write-Host "`n📁 Setting up website files..." -ForegroundColor Yellow
$setupCommands = @(
    "mkdir -p /var/www/omega",
    "rm -rf /var/www/html/*",
    "cd /tmp/omega-deploy && find . -name '*.html' -exec cp {} /var/www/omega/ \;",
    "cd /tmp/omega-deploy && find . -name '*.css' -exec cp {} /var/www/omega/ \;",
    "cd /tmp/omega-deploy && find . -name '*.js' -exec cp {} /var/www/omega/ \;", 
    "cd /tmp/omega-deploy && find . -name '*.svg' -exec cp {} /var/www/omega/ \;",
    "cd /tmp/omega-deploy && find . -name '*.md' -exec cp {} /var/www/omega/ \;",
    "ls -la /var/www/omega/",
    "chown -R www-data:www-data /var/www/omega",
    "chmod -R 755 /var/www/omega"
)

foreach ($cmd in $setupCommands) {
    Invoke-SSHCommand -Command $cmd
}

# Step 4: Configure nginx for OMEGA
Write-Host "`n⚙️ Configuring nginx..." -ForegroundColor Yellow

# Create nginx configuration
$nginxConfig = @"
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/omega;
    index index.html index.htm;
    
    server_name www.omegalang.xyz omegalang.xyz _;
    
    location / {
        try_files \`$uri \`$uri/ =404;
        add_header Cache-Control 'no-cache, no-store, must-revalidate';
        add_header Pragma 'no-cache';
        add_header Expires '0';
    }
    
    location ~* \.(css|js|svg|png|jpg|jpeg|gif|ico)$ {
        expires 1d;
        add_header Cache-Control 'public, immutable';
    }
    
    error_page 404 /index.html;
}
"@

# Write config to temporary file first
$tempConfig = "/tmp/omega-nginx.conf"
$configContent = $nginxConfig -replace '"', '\"' -replace '`', '\`'

Invoke-SSHCommand -Command "cat > $tempConfig << 'EOF'`n$nginxConfig`nEOF"
Invoke-SSHCommand -Command "cp $tempConfig /etc/nginx/sites-available/default"
Invoke-SSHCommand -Command "nginx -t"

# Step 5: Restart nginx
Write-Host "`n🔄 Restarting nginx..." -ForegroundColor Yellow
Invoke-SSHCommand -Command "systemctl restart nginx"
Invoke-SSHCommand -Command "systemctl status nginx --no-pager"

# Step 6: Test the website
Write-Host "`n🧪 Testing website..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Test from server itself
Invoke-SSHCommand -Command "curl -I http://localhost"
Invoke-SSHCommand -Command "curl -s http://localhost | head -20"

# Test from external
Write-Host "`n🌐 Testing external access..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$ServerIP" -TimeoutSec 20 -ErrorAction Stop
    Write-Host "✅ SUCCESS! Website is accessible!" -ForegroundColor Green
    Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Content Length: $($response.Content.Length) bytes" -ForegroundColor Green
    
    # Check if it's our OMEGA content
    if ($response.Content -like "*OMEGA*" -or $response.Content -like "*Universal Blockchain*") {
        Write-Host "✅ OMEGA website content confirmed!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Content verification needed" -ForegroundColor Yellow
        Write-Host "   First 200 chars: $($response.Content.Substring(0, [Math]::Min(200, $response.Content.Length)))" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ External access test failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Additional diagnostics
    Write-Host "`n🔍 Running diagnostics..." -ForegroundColor Yellow
    Invoke-SSHCommand -Command "netstat -tlnp | grep :80"
    Invoke-SSHCommand -Command "ps aux | grep nginx"
    Invoke-SSHCommand -Command "tail -10 /var/log/nginx/error.log"
}

Write-Host "`n🎉 Web Server Setup Complete!" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "🌐 Direct IP: http://$ServerIP" -ForegroundColor White
Write-Host "🌐 Domain: http://www.omegalang.xyz (configure DNS)" -ForegroundColor White
Write-Host ""
Write-Host "📋 DNS Configuration Required:" -ForegroundColor Yellow
Write-Host "   A Record: www.omegalang.xyz -> $ServerIP" -ForegroundColor Gray
Write-Host "   A Record: omegalang.xyz -> $ServerIP" -ForegroundColor Gray