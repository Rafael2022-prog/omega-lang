# Direct Python Server for OMEGA Website
# Run server directly without systemd

param(
    [string]$ServerIP = "103.27.206.177",
    [string]$Username = "root",
    [string]$Password = "!eL3H!Ue^Ik2"
)

Write-Host "🚀 OMEGA Direct Server Setup" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

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

# Step 1: Kill any existing processes
Write-Host "`n🔄 Cleaning up existing processes..." -ForegroundColor Yellow
Invoke-SSHCommand -Command "pkill -f 'python.*server' || echo 'No existing servers'"
Invoke-SSHCommand -Command "systemctl unmask omega-server || echo 'Service not masked'"
Invoke-SSHCommand -Command "systemctl stop omega-server || echo 'Service not running'"

# Step 2: Verify files are in place
Write-Host "`n📁 Verifying website files..." -ForegroundColor Yellow
Invoke-SSHCommand -Command "ls -la /var/www/omega/"
Invoke-SSHCommand -Command "cat /var/www/omega/index.html | head -5"

# Step 3: Start server directly on port 8080 (non-privileged)
Write-Host "`n🐍 Starting Python server on port 8080..." -ForegroundColor Yellow

# Create a simple server script
$simpleServer = @"
import http.server
import socketserver
import os

os.chdir('/var/www/omega')
PORT = 8080

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.path = '/index.html'
        return super().do_GET()

with socketserver.TCPServer(('', PORT), Handler) as httpd:
    print(f'Server running on port {PORT}')
    httpd.serve_forever()
"@

Invoke-SSHCommand -Command "cat > /tmp/simple_server.py << 'EOF'`n$simpleServer`nEOF"

# Start server in background
Write-Host "Starting server in background..." -ForegroundColor Gray
$startCmd = "nohup python3 /tmp/simple_server.py > /tmp/server.log 2>&1 &"
Invoke-SSHCommand -Command $startCmd

# Wait a moment for server to start
Start-Sleep -Seconds 3

# Check if server is running
Write-Host "`n🔍 Checking server status..." -ForegroundColor Yellow
Invoke-SSHCommand -Command "ps aux | grep python"
Invoke-SSHCommand -Command "ss -tlnp | grep :8080 || echo 'Port 8080 not found'"
Invoke-SSHCommand -Command "cat /tmp/server.log"

# Test local connection
Write-Host "`n🧪 Testing local connection..." -ForegroundColor Yellow
Invoke-SSHCommand -Command "curl -I http://localhost:8080"

# Test external connection
Write-Host "`n🌐 Testing external connection..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

try {
    $response = Invoke-WebRequest -Uri "http://${ServerIP}:8080" -TimeoutSec 20 -ErrorAction Stop
    Write-Host "✅ SUCCESS! Website is accessible!" -ForegroundColor Green
    Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Content Length: $($response.Content.Length) bytes" -ForegroundColor Green
    
    # Check content
    if ($response.Content -like "*OMEGA*" -or $response.Content -like "*Universal Blockchain*") {
        Write-Host "✅ OMEGA website content confirmed!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Content check:" -ForegroundColor Yellow
        $preview = $response.Content.Substring(0, [Math]::Min(300, $response.Content.Length))
        Write-Host "   Preview: $preview" -ForegroundColor Gray
    }
    
    # Update todo list
    Write-Host "`n🎯 Deployment Status:" -ForegroundColor Cyan
    Write-Host "✅ Website successfully deployed and accessible" -ForegroundColor Green
    Write-Host "✅ Server running on port 8080" -ForegroundColor Green
    Write-Host "⏳ DNS configuration needed for domain" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ External test failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Additional diagnostics
    Write-Host "`n🔍 Additional diagnostics..." -ForegroundColor Yellow
    Invoke-SSHCommand -Command "ufw status"
    Invoke-SSHCommand -Command "iptables -L INPUT -n | grep 8080"
    Invoke-SSHCommand -Command "tail -20 /tmp/server.log"
}

Write-Host "`n🎉 Direct Server Setup Complete!" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "🌐 Website URL: http://${ServerIP}:8080" -ForegroundColor White
Write-Host "🌐 Domain (after DNS): http://www.omegalang.xyz:8080" -ForegroundColor White
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Configure DNS A records:" -ForegroundColor Gray
Write-Host "   - www.omegalang.xyz -> $ServerIP" -ForegroundColor Gray
Write-Host "   - omegalang.xyz -> $ServerIP" -ForegroundColor Gray
Write-Host "2. Test domain access after DNS propagation" -ForegroundColor Gray
Write-Host "3. Consider setting up SSL certificate" -ForegroundColor Gray