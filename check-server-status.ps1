# Check OMEGA Server Status and Troubleshoot
# Diagnose deployment issues

param(
    [string]$ServerIP = $env:OMEGA_SERVER_IP,
    [string]$Username = $env:OMEGA_SERVER_USER,
    [string]$Password = $env:OMEGA_SERVER_PASSWORD
)

$sshKeyPath = $env:OMEGA_SSH_KEY_PATH
$usingKey = [bool]$sshKeyPath

if (-not $ServerIP -or -not $Username -or ((-not $Password) -and -not $usingKey)) {
    Write-Host "❌ Kredensial server belum lengkap. Set OMEGA_SERVER_IP, OMEGA_SERVER_USER, dan OMEGA_SERVER_PASSWORD atau OMEGA_SSH_KEY_PATH." -ForegroundColor Red
    Write-Host 'Contoh (password): $env:OMEGA_SERVER_IP = "203.0.113.10"; $env:OMEGA_SERVER_USER = "root"; $env:OMEGA_SERVER_PASSWORD = "<password>"' -ForegroundColor Gray
    Write-Host 'Contoh (SSH key PuTTY): $env:OMEGA_SSH_KEY_PATH = "C:\\Users\\you\\.ssh\\id_rsa.ppk"' -ForegroundColor Gray
    exit 1
}

$sshAuthArgs = if ($usingKey) { "-i `"$sshKeyPath`"" } else { "-pw `"$Password`"" }

Write-Host "🔍 OMEGA Server Status Check" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

# Check if server is reachable
Write-Host "🌐 Testing server connectivity..." -ForegroundColor Yellow
try {
    $ping = Test-Connection -ComputerName $ServerIP -Count 2 -Quiet
    if ($ping) {
        Write-Host "✅ Server is reachable via ping" -ForegroundColor Green
    } else {
        Write-Host "❌ Server is not reachable via ping" -ForegroundColor Red
        return
    }
} catch {
    Write-Host "❌ Ping test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check SSH connectivity
Write-Host "🔐 Testing SSH connectivity..." -ForegroundColor Yellow
$sshTest = @"
@echo off
echo Testing SSH connection...
plink -batch $sshAuthArgs $Username@$ServerIP "echo 'SSH connection successful'"
"@

$sshTest | Out-File -FilePath "temp-ssh-test.bat" -Encoding ASCII

try {
    $sshResult = & cmd /c "temp-ssh-test.bat"
    Write-Host $sshResult
    if ($sshResult -like "*SSH connection successful*") {
        Write-Host "✅ SSH connection working" -ForegroundColor Green
    } else {
        Write-Host "⚠️  SSH connection may have issues" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ SSH test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check nginx status and configuration
Write-Host "🔧 Checking nginx status..." -ForegroundColor Yellow
$nginxCheck = @"
systemctl status nginx --no-pager
echo "--- Nginx Configuration Test ---"
nginx -t
echo "--- Listening Ports ---"
netstat -tlnp | grep :80
echo "--- Website Files ---"
ls -la /var/www/omega/
echo "--- Nginx Error Log (last 10 lines) ---"
tail -n 10 /var/log/nginx/error.log
"@

$nginxBatch = @"
@echo off
echo Checking nginx status...
plink -batch $sshAuthArgs $Username@$ServerIP "$nginxCheck"
"@

$nginxBatch | Out-File -FilePath "temp-nginx-check.bat" -Encoding ASCII

try {
    $nginxResult = & cmd /c "temp-nginx-check.bat"
    Write-Host $nginxResult
} catch {
    Write-Host "❌ Nginx check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Try to fix common issues
Write-Host "🔧 Attempting to fix common issues..." -ForegroundColor Yellow
$fixCommands = @"
# Restart nginx
systemctl stop nginx
systemctl start nginx
systemctl enable nginx

# Check if port 80 is available
netstat -tlnp | grep :80

# Ensure website files are in place
ls -la /var/www/omega/

# Check nginx configuration
nginx -t

# Check firewall (if ufw is installed)
ufw status || echo "UFW not installed"

# Final status check
systemctl status nginx --no-pager
echo "Fix attempt completed"
"@

$fixBatch = @"
@echo off
echo Attempting fixes...
plink -batch $sshAuthArgs $Username@$ServerIP "$fixCommands"
"@

$fixBatch | Out-File -FilePath "temp-fix.bat" -Encoding ASCII

try {
    $fixResult = & cmd /c "temp-fix.bat"
    Write-Host $fixResult
} catch {
    Write-Host "❌ Fix attempt failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Final connectivity test
Write-Host "🧪 Final connectivity test..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $response = Invoke-WebRequest -Uri "http://$ServerIP" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Website is now accessible! Status: $($response.StatusCode)" -ForegroundColor Green
    
    if ($response.Content -like "*OMEGA*") {
        Write-Host "✅ OMEGA content confirmed!" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Website still not accessible: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Manual troubleshooting may be required" -ForegroundColor Yellow
}

# Clean up
@("temp-ssh-test.bat", "temp-nginx-check.bat", "temp-fix.bat") | ForEach-Object {
    if (Test-Path $_) { Remove-Item $_ -Force }
}

Write-Host "`n📋 Troubleshooting Summary" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "If website is still not accessible, try:" -ForegroundColor White
Write-Host "1. Check server firewall settings" -ForegroundColor Gray
Write-Host "2. Verify nginx is running: systemctl status nginx" -ForegroundColor Gray
Write-Host "3. Check nginx error logs: tail -f /var/log/nginx/error.log" -ForegroundColor Gray
Write-Host "4. Ensure port 80 is open: netstat -tlnp | grep :80" -ForegroundColor Gray