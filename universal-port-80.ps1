# Universal Port 80 Setup for OMEGA Website
# This script works with different Linux distributions

Write-Host "=== OMEGA Website Universal Port 80 Setup ===" -ForegroundColor Cyan
Write-Host "Configuring server to serve website on standard port 80..." -ForegroundColor Yellow

$serverIP = "103.27.206.177"
$sshUser = "root"

try {
    Write-Host "`n1. Checking server system information..." -ForegroundColor Green
    ssh $sshUser@$serverIP @"
echo "=== System Information ==="
cat /etc/os-release 2>/dev/null || echo "OS release info not available"
echo ""
echo "=== Available Package Managers ==="
which yum 2>/dev/null && echo "YUM available" || echo "YUM not found"
which dnf 2>/dev/null && echo "DNF available" || echo "DNF not found"
which apt-get 2>/dev/null && echo "APT available" || echo "APT not found"
which pacman 2>/dev/null && echo "PACMAN available" || echo "PACMAN not found"
which zypper 2>/dev/null && echo "ZYPPER available" || echo "ZYPPER not found"
echo ""
echo "=== Current processes on port 80 ==="
lsof -i :80 2>/dev/null || netstat -tlnp | grep :80 2>/dev/null || ss -tlnp | grep :80 2>/dev/null || echo "No processes found on port 80"
"@

    Write-Host "`n2. Stopping current Python server and setting up simple HTTP server on port 80..." -ForegroundColor Green
    ssh $sshUser@$serverIP @"
# Stop any existing Python servers
pkill -f 'python.*http.server' 2>/dev/null || true
pkill -f 'python.*SimpleHTTPServer' 2>/dev/null || true

# Kill any process using port 80
lsof -ti:80 | xargs kill -9 2>/dev/null || true

# Ensure website directory exists and has correct files
ls -la /var/www/omega/ 2>/dev/null || echo "Website directory not found"

# Create a simple startup script for port 80
cat > /var/www/omega/start-server-80.sh << 'EOF'
#!/bin/bash
cd /var/www/omega
echo "Starting OMEGA website server on port 80..."
echo "Server started at: \$(date)"
python3 -m http.server 80 2>&1 | tee /var/log/omega-server.log &
echo "Server PID: \$!"
EOF

chmod +x /var/www/omega/start-server-80.sh

# Start the server on port 80
cd /var/www/omega
nohup python3 -m http.server 80 > /var/log/omega-server.log 2>&1 &
sleep 3

# Check if server is running
ps aux | grep 'python.*http.server.*80' | grep -v grep || echo "Server not found in process list"
"@

    Write-Host "`n3. Testing server accessibility..." -ForegroundColor Green
    Start-Sleep -Seconds 5
    
    # Test local access on server
    Write-Host "Testing local access on server..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP "curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://localhost/ 2>/dev/null || echo 'Local test failed - curl may not be available'"
    
    # Test external access via IP
    Write-Host "Testing external access via IP..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://$serverIP" -Method GET -TimeoutSec 15
        Write-Host "✅ IP Access: HTTP $($response.StatusCode) - Content Length: $($response.Content.Length)" -ForegroundColor Green
        
        if ($response.Content -match "OMEGA") {
            Write-Host "✅ Website content verified - OMEGA found!" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "❌ IP Access failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Trying alternative test..." -ForegroundColor Yellow
        
        # Try with curl from local machine if available
        try {
            $curlResult = curl -s -o /dev/null -w "%{http_code}" "http://$serverIP" 2>$null
            if ($curlResult -eq "200") {
                Write-Host "✅ Alternative test successful: HTTP 200" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Alternative test also failed" -ForegroundColor Red
        }
    }
    
    # Test external access via domain
    Write-Host "Testing external access via domain..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://omegalang.xyz" -Method GET -TimeoutSec 15
        Write-Host "✅ Domain Access: HTTP $($response.StatusCode) - Content Length: $($response.Content.Length)" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Domain Access failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`n4. Server status check..." -ForegroundColor Green
    ssh $sshUser@$serverIP @"
echo "=== Server Process Status ==="
ps aux | grep 'python.*http.server' | grep -v grep || echo "No Python HTTP server found"
echo ""
echo "=== Port 80 Status ==="
lsof -i :80 2>/dev/null || netstat -tlnp | grep :80 2>/dev/null || ss -tlnp | grep :80 2>/dev/null || echo "Port 80 not in use"
echo ""
echo "=== Recent Server Logs ==="
tail -10 /var/log/omega-server.log 2>/dev/null || echo "No server logs found"
"@

    Write-Host "`n=== Universal Port 80 Setup Summary ===" -ForegroundColor Cyan
    Write-Host "✅ System information checked" -ForegroundColor Green
    Write-Host "✅ Python HTTP server configured for port 80" -ForegroundColor Green
    Write-Host "✅ Server startup script created" -ForegroundColor Green
    Write-Host "`nWebsite should now be accessible at:" -ForegroundColor Yellow
    Write-Host "• http://omegalang.xyz" -ForegroundColor White
    Write-Host "• http://$serverIP" -ForegroundColor White
    
    Write-Host "`nServer management commands:" -ForegroundColor Yellow
    Write-Host "• Start: ssh root@$serverIP '/var/www/omega/start-server-80.sh'" -ForegroundColor White
    Write-Host "• Stop: ssh root@$serverIP 'pkill -f \"python.*http.server.*80\"'" -ForegroundColor White
    Write-Host "• Logs: ssh root@$serverIP 'tail -f /var/log/omega-server.log'" -ForegroundColor White

}
catch {
    Write-Host "❌ Error during universal port 80 setup: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check server connectivity and try again." -ForegroundColor Yellow
}

Write-Host "`nUniversal port 80 setup completed!" -ForegroundColor Cyan