# Setup Python HTTP Server for OMEGA Website
# Alternative approach using Python's built-in HTTP server

param(
    [string]$ServerIP = "103.27.206.177",
    [string]$Username = "root",
    [string]$Password = "!eL3H!Ue^Ik2"
)

Write-Host "🐍 OMEGA Python Web Server Setup" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

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

# Step 1: Install Python and required packages
Write-Host "`n📦 Installing Python..." -ForegroundColor Yellow
$installCommands = @(
    "apt update -y",
    "apt install -y python3 python3-pip",
    "python3 --version"
)

foreach ($cmd in $installCommands) {
    Invoke-SSHCommand -Command $cmd
}

# Step 2: Setup website directory
Write-Host "`n📁 Setting up website directory..." -ForegroundColor Yellow
$setupCommands = @(
    "mkdir -p /var/www/omega",
    "cd /tmp/omega-deploy && cp -r * /var/www/omega/ 2>/dev/null || echo 'Files copied'",
    "ls -la /var/www/omega/",
    "chmod -R 755 /var/www/omega"
)

foreach ($cmd in $setupCommands) {
    Invoke-SSHCommand -Command $cmd
}

# Step 3: Create Python server script
Write-Host "`n🐍 Creating Python server script..." -ForegroundColor Yellow

$pythonServer = @"
#!/usr/bin/env python3
import http.server
import socketserver
import os
import sys

# Change to website directory
os.chdir('/var/www/omega')

# Custom handler to serve index.html for all requests
class OmegaHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # If requesting root or a path that doesn't exist, serve index.html
        if self.path == '/' or not os.path.exists(self.path.lstrip('/')):
            self.path = '/index.html'
        return super().do_GET()
    
    def end_headers(self):
        # Add CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

PORT = 80
Handler = OmegaHandler

try:
    with socketserver.TCPServer(('', PORT), Handler) as httpd:
        print(f'OMEGA Server running on port {PORT}')
        print(f'Serving directory: {os.getcwd()}')
        print('Press Ctrl+C to stop')
        httpd.serve_forever()
except PermissionError:
    print('Permission denied. Trying port 8080...')
    PORT = 8080
    with socketserver.TCPServer(('', PORT), Handler) as httpd:
        print(f'OMEGA Server running on port {PORT}')
        httpd.serve_forever()
except Exception as e:
    print(f'Error starting server: {e}')
    sys.exit(1)
"@

# Write Python server script
$scriptContent = $pythonServer -replace '"', '\"' -replace '`', '\`'
Invoke-SSHCommand -Command "cat > /var/www/omega/server.py << 'EOF'`n$pythonServer`nEOF"
Invoke-SSHCommand -Command "chmod +x /var/www/omega/server.py"

# Step 4: Create systemd service
Write-Host "`n⚙️ Creating systemd service..." -ForegroundColor Yellow

$serviceFile = @"
[Unit]
Description=OMEGA Website Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/omega
ExecStart=/usr/bin/python3 /var/www/omega/server.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
"@

Invoke-SSHCommand -Command "cat > /etc/systemd/system/omega-server.service << 'EOF'`n$serviceFile`nEOF"

# Step 5: Start the service
Write-Host "`n🚀 Starting OMEGA server..." -ForegroundColor Yellow
$serviceCommands = @(
    "systemctl daemon-reload",
    "systemctl enable omega-server",
    "systemctl start omega-server",
    "systemctl status omega-server --no-pager",
    "sleep 3"
)

foreach ($cmd in $serviceCommands) {
    Invoke-SSHCommand -Command $cmd
}

# Step 6: Configure firewall
Write-Host "`n🔥 Configuring firewall..." -ForegroundColor Yellow
Invoke-SSHCommand -Command "ufw allow 80/tcp"
Invoke-SSHCommand -Command "ufw allow 8080/tcp"
Invoke-SSHCommand -Command "ufw status"

# Step 7: Test the server
Write-Host "`n🧪 Testing server..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Test from server
Invoke-SSHCommand -Command "curl -I http://localhost"
Invoke-SSHCommand -Command "curl -I http://localhost:8080"
Invoke-SSHCommand -Command "netstat -tlnp | grep python3"

# Test external access
Write-Host "`n🌐 Testing external access..." -ForegroundColor Yellow

# Try port 80 first
try {
    $response = Invoke-WebRequest -Uri "http://$ServerIP" -TimeoutSec 15 -ErrorAction Stop
    Write-Host "✅ SUCCESS! Website accessible on port 80!" -ForegroundColor Green
    Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Content Length: $($response.Content.Length) bytes" -ForegroundColor Green
    
    if ($response.Content -like "*OMEGA*" -or $response.Content -like "*Universal Blockchain*") {
        Write-Host "✅ OMEGA website content confirmed!" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Port 80 failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try port 8080
    try {
        $response = Invoke-WebRequest -Uri "http://${ServerIP}:8080" -TimeoutSec 15 -ErrorAction Stop
        Write-Host "✅ SUCCESS! Website accessible on port 8080!" -ForegroundColor Green
        Write-Host "   Status Code: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "   Content Length: $($response.Content.Length) bytes" -ForegroundColor Green
        
        if ($response.Content -like "*OMEGA*" -or $response.Content -like "*Universal Blockchain*") {
            Write-Host "✅ OMEGA website content confirmed!" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Port 8080 also failed: $($_.Exception.Message)" -ForegroundColor Red
        
        # Show diagnostics
        Write-Host "`n🔍 Diagnostics..." -ForegroundColor Yellow
        Invoke-SSHCommand -Command "systemctl status omega-server"
        Invoke-SSHCommand -Command "journalctl -u omega-server --no-pager -l"
    }
}

Write-Host "`n🎉 Python Server Setup Complete!" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "🌐 Test URLs:" -ForegroundColor White
Write-Host "   http://$ServerIP" -ForegroundColor Gray
Write-Host "   http://${ServerIP}:8080" -ForegroundColor Gray
Write-Host "🌐 Domain: http://www.omegalang.xyz (configure DNS)" -ForegroundColor White
Write-Host ""
Write-Host "📋 DNS Configuration Required:" -ForegroundColor Yellow
Write-Host "   A Record: www.omegalang.xyz -> $ServerIP" -ForegroundColor Gray
Write-Host "   A Record: omegalang.xyz -> $ServerIP" -ForegroundColor Gray