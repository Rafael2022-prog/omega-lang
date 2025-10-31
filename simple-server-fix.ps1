# Simple Server Fix for OMEGA Website
# Ensure nginx is running and configured correctly

param(
    [string]$ServerIP = "103.27.206.177",
    [string]$Username = "root",
    [string]$Password = "!eL3H!Ue^Ik2"
)

Write-Host "🔧 Simple OMEGA Server Fix" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan

# Execute commands one by one with proper escaping
$commands = @(
    "apt update",
    "apt install -y nginx",
    "systemctl enable nginx",
    "systemctl start nginx",
    "mkdir -p /var/www/omega",
    "cd /tmp/omega-deploy && cp *.html /var/www/omega/ 2>/dev/null || echo 'HTML files copied'",
    "cd /tmp/omega-deploy && cp *.css /var/www/omega/ 2>/dev/null || echo 'CSS files copied'", 
    "cd /tmp/omega-deploy && cp *.js /var/www/omega/ 2>/dev/null || echo 'JS files copied'",
    "cd /tmp/omega-deploy && cp *.svg /var/www/omega/ 2>/dev/null || echo 'SVG files copied'",
    "cd /tmp/omega-deploy && cp -r docs /var/www/omega/ 2>/dev/null || echo 'Docs copied'",
    "chown -R www-data:www-data /var/www/omega",
    "chmod -R 755 /var/www/omega"
)

foreach ($cmd in $commands) {
    Write-Host "Executing: $cmd" -ForegroundColor Gray
    $sshCmd = "plink -batch -pw `"$Password`" $Username@$ServerIP `"$cmd`""
    try {
        $result = & cmd /c $sshCmd
        if ($result) {
            Write-Host "  Result: $result" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Configure nginx with a simple configuration
Write-Host "`n🔧 Configuring nginx..." -ForegroundColor Yellow

$nginxConfig = @"
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/omega;
    index index.html;
    
    server_name _;
    
    location / {
        try_files `$uri `$uri/ =404;
    }
}
"@

# Write nginx config to server
$configCmd = "echo '$nginxConfig' > /etc/nginx/sites-available/default"
$sshConfigCmd = "plink -batch -pw `"$Password`" $Username@$ServerIP `"$configCmd`""

Write-Host "Writing nginx configuration..." -ForegroundColor Gray
try {
    & cmd /c $sshConfigCmd
    Write-Host "✅ Nginx configuration written" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to write nginx config: $($_.Exception.Message)" -ForegroundColor Red
}

# Restart nginx
Write-Host "`n🔄 Restarting nginx..." -ForegroundColor Yellow
$restartCommands = @(
    "nginx -t",
    "systemctl restart nginx", 
    "systemctl status nginx --no-pager -l"
)

foreach ($cmd in $restartCommands) {
    Write-Host "Executing: $cmd" -ForegroundColor Gray
    $sshCmd = "plink -batch -pw `"$Password`" $Username@$ServerIP `"$cmd`""
    try {
        $result = & cmd /c $sshCmd
        Write-Host "  $result" -ForegroundColor DarkGray
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Final test
Write-Host "`n🧪 Testing website..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

try {
    $response = Invoke-WebRequest -Uri "http://$ServerIP" -TimeoutSec 15 -ErrorAction Stop
    Write-Host "✅ SUCCESS! Website is accessible!" -ForegroundColor Green
    Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Content Length: $($response.Content.Length) bytes" -ForegroundColor Green
    
    if ($response.Content -like "*OMEGA*") {
        Write-Host "✅ OMEGA content confirmed!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Default nginx page detected - OMEGA content may need verification" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Website test failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try alternative test
    Write-Host "🔄 Trying alternative test..." -ForegroundColor Yellow
    try {
        $curlTest = "curl -I http://localhost"
        $curlCmd = "plink -batch -pw `"$Password`" $Username@$ServerIP `"$curlTest`""
        $curlResult = & cmd /c $curlCmd
        Write-Host "Curl test result: $curlResult" -ForegroundColor Gray
    } catch {
        Write-Host "Curl test also failed" -ForegroundColor Red
    }
}

Write-Host "`n🎉 Server Fix Complete!" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host "🌐 Test URL: http://$ServerIP" -ForegroundColor White
Write-Host "🌐 Domain: http://www.omegalang.xyz (after DNS setup)" -ForegroundColor White