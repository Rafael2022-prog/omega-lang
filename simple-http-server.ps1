# Simple HTTP Server for OMEGA Website
# Use Python's built-in HTTP server

param(
    [string]$ServerIP = "103.27.206.177",
    [string]$Username = "root",
    [string]$Password = "!eL3H!Ue^Ik2"
)

Write-Host "🌐 OMEGA Simple HTTP Server" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

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

# Step 1: Verify Python installation
Write-Host "`n🐍 Checking Python..." -ForegroundColor Yellow
Invoke-SSHCommand -Command "python3 --version"
Invoke-SSHCommand -Command "which python3"

# Step 2: Verify website files
Write-Host "`n📁 Checking website files..." -ForegroundColor Yellow
Invoke-SSHCommand -Command "ls -la /var/www/omega/"
Invoke-SSHCommand -Command "wc -l /var/www/omega/index.html"

# Step 3: Kill any existing servers
Write-Host "`n🔄 Cleaning up..." -ForegroundColor Yellow
Invoke-SSHCommand -Command "pkill -f 'python.*http.server' || echo 'No servers to kill'"
Invoke-SSHCommand -Command "pkill -f 'SimpleHTTPServer' || echo 'No servers to kill'"

# Step 4: Start simple HTTP server
Write-Host "`n🚀 Starting HTTP server..." -ForegroundColor Yellow

# Try Python 3 first
Write-Host "Starting Python 3 HTTP server on port 8080..." -ForegroundColor Gray
$serverCmd = "cd /var/www/omega && nohup python3 -m http.server 8080 > /tmp/http_server.log 2>&1 &"
Invoke-SSHCommand -Command $serverCmd

# Wait for server to start
Start-Sleep -Seconds 5

# Check if server is running
Write-Host "`n🔍 Checking server..." -ForegroundColor Yellow
Invoke-SSHCommand -Command "ps aux | grep 'http.server'"
Invoke-SSHCommand -Command "cat /tmp/http_server.log"

# Check if port is listening
Invoke-SSHCommand -Command "ss -tlnp | grep :8080 || netstat -tlnp | grep :8080 || echo 'Port check failed'"

# Test local connection
Write-Host "`n🧪 Testing local connection..." -ForegroundColor Yellow
Invoke-SSHCommand -Command "curl -I http://localhost:8080 || echo 'Local test failed'"

# Test external connection
Write-Host "`n🌐 Testing external connection..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

try {
    $response = Invoke-WebRequest -Uri "http://${ServerIP}:8080" -TimeoutSec 25 -ErrorAction Stop
    Write-Host "✅ SUCCESS! OMEGA Website is LIVE!" -ForegroundColor Green
    Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Content Length: $($response.Content.Length) bytes" -ForegroundColor Green
    
    # Verify OMEGA content
    if ($response.Content -like "*OMEGA*" -or $response.Content -like "*Universal Blockchain*" -or $response.Content -like "*blockchain*") {
        Write-Host "✅ OMEGA content verified!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Content preview:" -ForegroundColor Yellow
        $preview = $response.Content.Substring(0, [Math]::Min(200, $response.Content.Length))
        Write-Host "   $preview" -ForegroundColor Gray
    }
    
    Write-Host "`n🎯 DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Green
    
} catch {
    Write-Host "❌ External connection failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try alternative port
    Write-Host "`n🔄 Trying alternative setup..." -ForegroundColor Yellow
    
    # Start on port 3000
    $altCmd = "cd /var/www/omega && nohup python3 -m http.server 3000 > /tmp/http_server_3000.log 2>&1 &"
    Invoke-SSHCommand -Command $altCmd
    Start-Sleep -Seconds 3
    
    try {
        $response = Invoke-WebRequest -Uri "http://${ServerIP}:3000" -TimeoutSec 15 -ErrorAction Stop
        Write-Host "✅ SUCCESS on port 3000!" -ForegroundColor Green
        Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Port 3000 also failed" -ForegroundColor Red
        
        # Show diagnostics
        Write-Host "`n🔍 Diagnostics..." -ForegroundColor Yellow
        Invoke-SSHCommand -Command "ps aux | grep python"
        Invoke-SSHCommand -Command "cat /tmp/http_server.log"
        Invoke-SSHCommand -Command "ufw status numbered"
    }
}

Write-Host "`n🎉 Server Setup Complete!" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "🌐 Website URLs to test:" -ForegroundColor White
Write-Host "   http://${ServerIP}:8080" -ForegroundColor Gray
Write-Host "   http://${ServerIP}:3000" -ForegroundColor Gray
Write-Host ""
Write-Host "🌐 Domain (after DNS setup):" -ForegroundColor White
Write-Host "   http://www.omegalang.xyz:8080" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 DNS Configuration:" -ForegroundColor Yellow
Write-Host "   A Record: www.omegalang.xyz -> $ServerIP" -ForegroundColor Gray
Write-Host "   A Record: omegalang.xyz -> $ServerIP" -ForegroundColor Gray