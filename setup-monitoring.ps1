# Monitoring System Setup for OMEGA Website
# This script sets up comprehensive monitoring for uptime and performance

Write-Host "=== OMEGA Website Monitoring System Setup ===" -ForegroundColor Cyan
Write-Host "Setting up monitoring for uptime and performance..." -ForegroundColor Yellow

$serverIP = "103.27.206.177"
$sshUser = "root"
$domain = "omegalang.xyz"

try {
    Write-Host "`n1. Installing monitoring tools on server..." -ForegroundColor Green
    $monitoringSetup = @"
# Install monitoring tools
dnf install -y htop iotop nethogs sysstat curl wget

# Create monitoring directory
mkdir -p /opt/omega-monitoring
mkdir -p /var/log/omega-monitoring

# Create system monitoring script
cat > /opt/omega-monitoring/system-monitor.sh << 'EOF'
#!/bin/bash
# OMEGA System Monitoring Script

LOG_DIR="/var/log/omega-monitoring"
DATE=\$(date '+%Y-%m-%d %H:%M:%S')

# System metrics
echo "[\$DATE] === System Metrics ===" >> \$LOG_DIR/system.log
echo "CPU Usage: \$(top -bn1 | grep "Cpu(s)" | awk '{print \$2}' | cut -d'%' -f1)" >> \$LOG_DIR/system.log
echo "Memory Usage: \$(free | grep Mem | awk '{printf "%.2f%%", \$3/\$2 * 100.0}')" >> \$LOG_DIR/system.log
echo "Disk Usage: \$(df -h / | awk 'NR==2{printf "%s", \$5}')" >> \$LOG_DIR/system.log
echo "Load Average: \$(uptime | awk -F'load average:' '{print \$2}')" >> \$LOG_DIR/system.log
echo "" >> \$LOG_DIR/system.log

# Network connections
echo "[\$DATE] Active Connections: \$(netstat -an | grep :80 | wc -l)" >> \$LOG_DIR/network.log

# Process monitoring
if pgrep -f "python.*http.server" > /dev/null; then
    echo "[\$DATE] OMEGA Server: RUNNING" >> \$LOG_DIR/service.log
else
    echo "[\$DATE] OMEGA Server: STOPPED" >> \$LOG_DIR/service.log
fi
EOF

chmod +x /opt/omega-monitoring/system-monitor.sh

# Create website uptime monitoring script
cat > /opt/omega-monitoring/uptime-monitor.sh << 'EOF'
#!/bin/bash
# OMEGA Website Uptime Monitoring Script

LOG_DIR="/var/log/omega-monitoring"
DATE=\$(date '+%Y-%m-%d %H:%M:%S')
DOMAIN="$domain"

# Test HTTP
HTTP_STATUS=\$(curl -s -o /dev/null -w "%{http_code}" http://\$DOMAIN --max-time 10)
if [ "\$HTTP_STATUS" = "200" ] || [ "\$HTTP_STATUS" = "301" ] || [ "\$HTTP_STATUS" = "302" ]; then
    echo "[\$DATE] HTTP Status: \$HTTP_STATUS - OK" >> \$LOG_DIR/uptime.log
else
    echo "[\$DATE] HTTP Status: \$HTTP_STATUS - ERROR" >> \$LOG_DIR/uptime.log
fi

# Test HTTPS (if available)
HTTPS_STATUS=\$(curl -s -o /dev/null -w "%{http_code}" https://\$DOMAIN --max-time 10 2>/dev/null)
if [ "\$HTTPS_STATUS" = "200" ]; then
    echo "[\$DATE] HTTPS Status: \$HTTPS_STATUS - OK" >> \$LOG_DIR/uptime.log
else
    echo "[\$DATE] HTTPS Status: \$HTTPS_STATUS - ERROR" >> \$LOG_DIR/uptime.log
fi

# Response time test
RESPONSE_TIME=\$(curl -s -o /dev/null -w "%{time_total}" http://\$DOMAIN --max-time 10)
echo "[\$DATE] Response Time: \${RESPONSE_TIME}s" >> \$LOG_DIR/performance.log
EOF

chmod +x /opt/omega-monitoring/uptime-monitor.sh

# Create log rotation script
cat > /opt/omega-monitoring/rotate-logs.sh << 'EOF'
#!/bin/bash
# Log rotation script

LOG_DIR="/var/log/omega-monitoring"
DATE=\$(date '+%Y%m%d')

# Rotate logs if they're larger than 10MB
for log in system.log network.log service.log uptime.log performance.log; do
    if [ -f "\$LOG_DIR/\$log" ] && [ \$(stat -f%z "\$LOG_DIR/\$log" 2>/dev/null || stat -c%s "\$LOG_DIR/\$log") -gt 10485760 ]; then
        mv "\$LOG_DIR/\$log" "\$LOG_DIR/\$log.\$DATE"
        touch "\$LOG_DIR/\$log"
    fi
done
EOF

chmod +x /opt/omega-monitoring/rotate-logs.sh

echo "Monitoring tools installed!"
"@

    Write-Host "Installing monitoring tools..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP $monitoringSetup

    Write-Host "`n2. Setting up cron jobs for monitoring..." -ForegroundColor Green
    $cronSetup = @"
# Setup cron jobs for monitoring
(crontab -l 2>/dev/null; echo "# OMEGA Monitoring Jobs") | crontab -
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/omega-monitoring/system-monitor.sh") | crontab -
(crontab -l 2>/dev/null; echo "*/2 * * * * /opt/omega-monitoring/uptime-monitor.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/omega-monitoring/rotate-logs.sh") | crontab -

# Start monitoring immediately
/opt/omega-monitoring/system-monitor.sh
/opt/omega-monitoring/uptime-monitor.sh

echo "Cron jobs configured!"
crontab -l
"@

    Write-Host "Setting up cron jobs..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP $cronSetup

    Write-Host "`n3. Creating monitoring dashboard script..." -ForegroundColor Green
    
    $dashboardScript = @"
# OMEGA Website Monitoring Dashboard
Write-Host "=== OMEGA Website Monitoring Dashboard ===" -ForegroundColor Cyan

`$serverIP = "$serverIP"
`$sshUser = "$sshUser"
`$domain = "$domain"

function Show-SystemStatus {
    Write-Host "`n📊 System Status:" -ForegroundColor Yellow
    try {
        `$systemInfo = ssh `$sshUser@`$serverIP "uptime; free -h; df -h /"
        Write-Host `$systemInfo -ForegroundColor Gray
    }
    catch {
        Write-Host "❌ Unable to fetch system status" -ForegroundColor Red
    }
}

function Show-ServiceStatus {
    Write-Host "`n🔧 Service Status:" -ForegroundColor Yellow
    try {
        `$serviceInfo = ssh `$sshUser@`$serverIP "pgrep -f 'python.*http.server' && echo 'OMEGA Server: RUNNING' || echo 'OMEGA Server: STOPPED'"
        Write-Host `$serviceInfo -ForegroundColor Gray
    }
    catch {
        Write-Host "❌ Unable to fetch service status" -ForegroundColor Red
    }
}

function Show-WebsiteStatus {
    Write-Host "`n🌐 Website Status:" -ForegroundColor Yellow
    
    # Test HTTP
    try {
        `$httpResponse = Invoke-WebRequest -Uri "http://`$domain" -Method GET -TimeoutSec 10
        Write-Host "✅ HTTP: `$(`$httpResponse.StatusCode) - Response Time: `$(`$httpResponse.Headers.'X-Response-Time' -or 'N/A')" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ HTTP: Failed - `$(`$_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test HTTPS
    try {
        `$httpsResponse = Invoke-WebRequest -Uri "https://`$domain" -Method GET -TimeoutSec 10
        Write-Host "✅ HTTPS: `$(`$httpsResponse.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ HTTPS: Not available or failed" -ForegroundColor Yellow
    }
}

function Show-RecentLogs {
    Write-Host "`n📋 Recent Monitoring Logs:" -ForegroundColor Yellow
    try {
        Write-Host "System Logs (Last 5 entries):" -ForegroundColor Cyan
        ssh `$sshUser@`$serverIP "tail -5 /var/log/omega-monitoring/system.log 2>/dev/null || echo 'No system logs yet'"
        
        Write-Host "`nUptime Logs (Last 5 entries):" -ForegroundColor Cyan
        ssh `$sshUser@`$serverIP "tail -5 /var/log/omega-monitoring/uptime.log 2>/dev/null || echo 'No uptime logs yet'"
        
        Write-Host "`nPerformance Logs (Last 5 entries):" -ForegroundColor Cyan
        ssh `$sshUser@`$serverIP "tail -5 /var/log/omega-monitoring/performance.log 2>/dev/null || echo 'No performance logs yet'"
    }
    catch {
        Write-Host "❌ Unable to fetch logs" -ForegroundColor Red
    }
}

function Show-Menu {
    Write-Host "`n=== Monitoring Options ===" -ForegroundColor Cyan
    Write-Host "1. Show System Status" -ForegroundColor White
    Write-Host "2. Show Service Status" -ForegroundColor White
    Write-Host "3. Show Website Status" -ForegroundColor White
    Write-Host "4. Show Recent Logs" -ForegroundColor White
    Write-Host "5. Show All Status" -ForegroundColor White
    Write-Host "6. Exit" -ForegroundColor White
    Write-Host ""
}

# Main dashboard loop
do {
    Show-Menu
    `$choice = Read-Host "Select option (1-6)"
    
    switch (`$choice) {
        "1" { Show-SystemStatus }
        "2" { Show-ServiceStatus }
        "3" { Show-WebsiteStatus }
        "4" { Show-RecentLogs }
        "5" { 
            Show-SystemStatus
            Show-ServiceStatus
            Show-WebsiteStatus
            Show-RecentLogs
        }
        "6" { 
            Write-Host "Exiting monitoring dashboard..." -ForegroundColor Yellow
            break
        }
        default { Write-Host "Invalid option. Please select 1-6." -ForegroundColor Red }
    }
    
    if (`$choice -ne "6") {
        Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
        Read-Host
    }
} while (`$choice -ne "6")

Write-Host "Monitoring dashboard closed." -ForegroundColor Cyan
"@

    $dashboardScript | Out-File -FilePath "R:\OMEGA\monitoring-dashboard.ps1" -Encoding UTF8
    Write-Host "✅ Monitoring dashboard created: monitoring-dashboard.ps1" -ForegroundColor Green

    Write-Host "`n4. Testing monitoring system..." -ForegroundColor Green
    Start-Sleep -Seconds 5
    
    # Test monitoring
    Write-Host "Testing monitoring system..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP "ls -la /var/log/omega-monitoring/ && echo '=== Recent Logs ===' && tail -3 /var/log/omega-monitoring/*.log 2>/dev/null || echo 'Logs are being generated...'"

    Write-Host "`n=== Monitoring System Setup Summary ===" -ForegroundColor Cyan
    Write-Host "✅ System monitoring tools installed" -ForegroundColor Green
    Write-Host "✅ Uptime monitoring configured" -ForegroundColor Green
    Write-Host "✅ Performance monitoring enabled" -ForegroundColor Green
    Write-Host "✅ Automated log rotation setup" -ForegroundColor Green
    Write-Host "✅ Cron jobs configured (every 2-5 minutes)" -ForegroundColor Green
    Write-Host "✅ Monitoring dashboard created" -ForegroundColor Green
    
    Write-Host "`nMonitoring Features:" -ForegroundColor Yellow
    Write-Host "• System metrics (CPU, Memory, Disk)" -ForegroundColor White
    Write-Host "• Website uptime monitoring" -ForegroundColor White
    Write-Host "• Response time tracking" -ForegroundColor White
    Write-Host "• Service status monitoring" -ForegroundColor White
    Write-Host "• Automated log rotation" -ForegroundColor White
    
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "• Run .\monitoring-dashboard.ps1 for interactive monitoring" -ForegroundColor White
    Write-Host "• Logs stored in /var/log/omega-monitoring/ on server" -ForegroundColor White
    Write-Host "• Monitoring runs automatically every 2-5 minutes" -ForegroundColor White

}
catch {
    Write-Host "❌ Error during monitoring setup: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nMonitoring system setup completed!" -ForegroundColor Cyan