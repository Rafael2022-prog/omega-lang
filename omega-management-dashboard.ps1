# OMEGA Website Management Dashboard
# Comprehensive management interface for all OMEGA services

Write-Host "=== OMEGA Website Management Dashboard ===" -ForegroundColor Cyan
Write-Host "Universal management interface for OMEGA services" -ForegroundColor Yellow

$serverIP = "103.27.206.177"
$sshUser = "root"
$domain = "omegalang.xyz"

# Service status functions
function Test-ServerConnection {
    try {
        $result = ssh -o ConnectTimeout=5 $sshUser@$serverIP "echo 'Connected'"
        return $result -eq "Connected"
    }
    catch {
        return $false
    }
}

function Get-ServiceStatus {
    Write-Host "`n🔧 Service Status:" -ForegroundColor Yellow
    
    if (-not (Test-ServerConnection)) {
        Write-Host "❌ Server connection failed" -ForegroundColor Red
        return
    }
    
    try {
        # Check OMEGA server
        $omegaStatus = ssh $sshUser@$serverIP "pgrep -f 'python.*http.server' && echo 'RUNNING' || echo 'STOPPED'"
        $statusColor = if ($omegaStatus -eq "RUNNING") { "Green" } else { "Red" }
        Write-Host "OMEGA Server: $omegaStatus" -ForegroundColor $statusColor
        
        # Check system resources
        $systemInfo = ssh $sshUser@$serverIP "uptime | awk '{print \`$1, \`$2, \`$3, \`$4, \`$5}'; free -h | grep Mem | awk '{print \"Memory:\", \`$3\"/\"\`$2}'; df -h / | tail -1 | awk '{print \"Disk:\", \`$5, \"used\"}'"
        Write-Host $systemInfo -ForegroundColor Gray
        
        # Check monitoring
        $monitoringStatus = ssh $sshUser@$serverIP "crontab -l | grep -q omega-monitoring && echo 'ACTIVE' || echo 'INACTIVE'"
        $monitorColor = if ($monitoringStatus -eq "ACTIVE") { "Green" } else { "Yellow" }
        Write-Host "Monitoring: $monitoringStatus" -ForegroundColor $monitorColor
        
        # Check backup
        $backupStatus = ssh $sshUser@$serverIP "crontab -l | grep -q omega-backup && echo 'ACTIVE' || echo 'INACTIVE'"
        $backupColor = if ($backupStatus -eq "ACTIVE") { "Green" } else { "Yellow" }
        Write-Host "Backup: $backupStatus" -ForegroundColor $backupColor
        
    }
    catch {
        Write-Host "❌ Unable to fetch service status: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-WebsiteStatus {
    Write-Host "`n🌐 Website Status:" -ForegroundColor Yellow
    
    # Test HTTP
    try {
        $httpResponse = Invoke-WebRequest -Uri "http://$domain" -Method GET -TimeoutSec 10
        Write-Host "✅ HTTP ($domain): $($httpResponse.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ HTTP ($domain): Failed" -ForegroundColor Red
    }
    
    # Test IP access
    try {
        $ipResponse = Invoke-WebRequest -Uri "http://$serverIP" -Method GET -TimeoutSec 10
        Write-Host "✅ IP ($serverIP): $($ipResponse.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ IP ($serverIP): Failed" -ForegroundColor Red
    }
    
    # Test HTTPS
    try {
        $httpsResponse = Invoke-WebRequest -Uri "https://$domain" -Method GET -TimeoutSec 10
        Write-Host "✅ HTTPS ($domain): $($httpsResponse.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ HTTPS ($domain): Not available" -ForegroundColor Yellow
    }
    
    # Test WWW subdomain
    try {
        $wwwResponse = Invoke-WebRequest -Uri "http://www.$domain" -Method GET -TimeoutSec 10
        Write-Host "✅ WWW (www.$domain): $($wwwResponse.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ WWW (www.$domain): Not configured" -ForegroundColor Yellow
    }
}

function Start-OmegaServer {
    Write-Host "`n🚀 Starting OMEGA Server..." -ForegroundColor Yellow
    try {
        ssh $sshUser@$serverIP "cd /var/www/omega && nohup python3 -m http.server 80 > /dev/null 2>&1 &"
        Start-Sleep -Seconds 3
        $status = ssh $sshUser@$serverIP "pgrep -f 'python.*http.server' && echo 'STARTED' || echo 'FAILED'"
        if ($status -eq "STARTED") {
            Write-Host "✅ OMEGA Server started successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to start OMEGA Server" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Error starting server: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Stop-OmegaServer {
    Write-Host "`n🛑 Stopping OMEGA Server..." -ForegroundColor Yellow
    try {
        ssh $sshUser@$serverIP "pkill -f 'python.*http.server'"
        Start-Sleep -Seconds 2
        $status = ssh $sshUser@$serverIP "pgrep -f 'python.*http.server' && echo 'STILL_RUNNING' || echo 'STOPPED'"
        if ($status -eq "STOPPED") {
            Write-Host "✅ OMEGA Server stopped successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Server may still be running" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Error stopping server: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Restart-OmegaServer {
    Write-Host "`n🔄 Restarting OMEGA Server..." -ForegroundColor Yellow
    Stop-OmegaServer
    Start-Sleep -Seconds 2
    Start-OmegaServer
}

function Show-RecentLogs {
    Write-Host "`n📋 Recent System Logs:" -ForegroundColor Yellow
    try {
        Write-Host "Monitoring Logs:" -ForegroundColor Cyan
        ssh $sshUser@$serverIP "tail -5 /var/log/omega-monitoring/uptime.log 2>/dev/null || echo 'No monitoring logs'"
        
        Write-Host "`nBackup Logs:" -ForegroundColor Cyan
        ssh $sshUser@$serverIP "tail -5 /var/backups/omega/backup.log 2>/dev/null || echo 'No backup logs'"
        
        Write-Host "`nSystem Logs:" -ForegroundColor Cyan
        ssh $sshUser@$serverIP "tail -5 /var/log/omega-monitoring/system.log 2>/dev/null || echo 'No system logs'"
    }
    catch {
        Write-Host "❌ Unable to fetch logs" -ForegroundColor Red
    }
}

function Run-SSL-Setup {
    Write-Host "`n🔒 Running SSL Certificate Setup..." -ForegroundColor Yellow
    if (Test-Path "R:\OMEGA\setup-ssl-certificate.ps1") {
        & "R:\OMEGA\setup-ssl-certificate.ps1"
    } else {
        Write-Host "❌ SSL setup script not found" -ForegroundColor Red
    }
}

function Run-WWW-Setup {
    Write-Host "`n🌐 Running WWW Subdomain Setup..." -ForegroundColor Yellow
    if (Test-Path "R:\OMEGA\configure-www-subdomain.ps1") {
        & "R:\OMEGA\configure-www-subdomain.ps1"
    } else {
        Write-Host "❌ WWW setup script not found" -ForegroundColor Red
    }
}

function Run-Monitoring-Setup {
    Write-Host "`n📊 Running Monitoring Setup..." -ForegroundColor Yellow
    if (Test-Path "R:\OMEGA\setup-monitoring.ps1") {
        & "R:\OMEGA\setup-monitoring.ps1"
    } else {
        Write-Host "❌ Monitoring setup script not found" -ForegroundColor Red
    }
}

function Run-Backup-Setup {
    Write-Host "`n💾 Running Backup Setup..." -ForegroundColor Yellow
    if (Test-Path "R:\OMEGA\setup-backup-system.ps1") {
        & "R:\OMEGA\setup-backup-system.ps1"
    } else {
        Write-Host "❌ Backup setup script not found" -ForegroundColor Red
    }
}

function Open-MonitoringDashboard {
    Write-Host "`n📊 Opening Monitoring Dashboard..." -ForegroundColor Yellow
    if (Test-Path "R:\OMEGA\monitoring-dashboard.ps1") {
        & "R:\OMEGA\monitoring-dashboard.ps1"
    } else {
        Write-Host "❌ Monitoring dashboard not found" -ForegroundColor Red
    }
}

function Open-BackupManager {
    Write-Host "`n💾 Opening Backup Manager..." -ForegroundColor Yellow
    if (Test-Path "R:\OMEGA\backup-manager.ps1") {
        & "R:\OMEGA\backup-manager.ps1"
    } else {
        Write-Host "❌ Backup manager not found" -ForegroundColor Red
    }
}

function Show-SystemInfo {
    Write-Host "`n💻 System Information:" -ForegroundColor Yellow
    Write-Host "Server IP: $serverIP" -ForegroundColor White
    Write-Host "Domain: $domain" -ForegroundColor White
    Write-Host "SSH User: $sshUser" -ForegroundColor White
    
    if (Test-ServerConnection) {
        Write-Host "Connection: ✅ Connected" -ForegroundColor Green
        try {
            $osInfo = ssh $sshUser@$serverIP "cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"'"
            Write-Host "OS: $osInfo" -ForegroundColor White
        }
        catch {
            Write-Host "OS: Unable to detect" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Connection: ❌ Failed" -ForegroundColor Red
    }
}

function Show-QuickActions {
    Write-Host "`n⚡ Quick Actions:" -ForegroundColor Yellow
    Write-Host "1. Start OMEGA Server" -ForegroundColor White
    Write-Host "2. Stop OMEGA Server" -ForegroundColor White
    Write-Host "3. Restart OMEGA Server" -ForegroundColor White
    Write-Host "4. Show Recent Logs" -ForegroundColor White
    Write-Host "5. Back to Main Menu" -ForegroundColor White
}

function Show-SetupMenu {
    Write-Host "`n🛠️ Setup & Configuration:" -ForegroundColor Yellow
    Write-Host "1. SSL Certificate Setup" -ForegroundColor White
    Write-Host "2. WWW Subdomain Setup" -ForegroundColor White
    Write-Host "3. Monitoring Setup" -ForegroundColor White
    Write-Host "4. Backup System Setup" -ForegroundColor White
    Write-Host "5. Back to Main Menu" -ForegroundColor White
}

function Show-ManagementMenu {
    Write-Host "`n🎛️ Management Tools:" -ForegroundColor Yellow
    Write-Host "1. Monitoring Dashboard" -ForegroundColor White
    Write-Host "2. Backup Manager" -ForegroundColor White
    Write-Host "3. System Information" -ForegroundColor White
    Write-Host "4. Back to Main Menu" -ForegroundColor White
}

function Show-MainMenu {
    Clear-Host
    Write-Host "=== OMEGA Website Management Dashboard ===" -ForegroundColor Cyan
    Write-Host "Server: $serverIP | Domain: $domain" -ForegroundColor Gray
    
    Get-ServiceStatus
    Get-WebsiteStatus
    
    Write-Host "`n=== Main Menu ===" -ForegroundColor Cyan
    Write-Host "1. Quick Actions" -ForegroundColor White
    Write-Host "2. Setup & Configuration" -ForegroundColor White
    Write-Host "3. Management Tools" -ForegroundColor White
    Write-Host "4. Refresh Status" -ForegroundColor White
    Write-Host "5. Exit" -ForegroundColor White
    Write-Host ""
}

# Main dashboard loop
do {
    Show-MainMenu
    $choice = Read-Host "Select option (1-5)"
    
    switch ($choice) {
        "1" {
            do {
                Show-QuickActions
                $quickChoice = Read-Host "Select quick action (1-5)"
                switch ($quickChoice) {
                    "1" { Start-OmegaServer }
                    "2" { Stop-OmegaServer }
                    "3" { Restart-OmegaServer }
                    "4" { Show-RecentLogs }
                    "5" { break }
                    default { Write-Host "Invalid option" -ForegroundColor Red }
                }
                if ($quickChoice -ne "5") {
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
                    Read-Host
                }
            } while ($quickChoice -ne "5")
        }
        "2" {
            do {
                Show-SetupMenu
                $setupChoice = Read-Host "Select setup option (1-5)"
                switch ($setupChoice) {
                    "1" { Run-SSL-Setup }
                    "2" { Run-WWW-Setup }
                    "3" { Run-Monitoring-Setup }
                    "4" { Run-Backup-Setup }
                    "5" { break }
                    default { Write-Host "Invalid option" -ForegroundColor Red }
                }
                if ($setupChoice -ne "5") {
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
                    Read-Host
                }
            } while ($setupChoice -ne "5")
        }
        "3" {
            do {
                Show-ManagementMenu
                $mgmtChoice = Read-Host "Select management option (1-4)"
                switch ($mgmtChoice) {
                    "1" { Open-MonitoringDashboard }
                    "2" { Open-BackupManager }
                    "3" { Show-SystemInfo }
                    "4" { break }
                    default { Write-Host "Invalid option" -ForegroundColor Red }
                }
                if ($mgmtChoice -ne "4") {
                    Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
                    Read-Host
                }
            } while ($mgmtChoice -ne "4")
        }
        "4" {
            Write-Host "Refreshing status..." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
        "5" {
            Write-Host "Exiting OMEGA Management Dashboard..." -ForegroundColor Yellow
            break
        }
        default {
            Write-Host "Invalid option. Please select 1-5." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($choice -ne "5")

Write-Host "`n=== OMEGA Management Dashboard Closed ===" -ForegroundColor Cyan
Write-Host "Thank you for using OMEGA Management Dashboard!" -ForegroundColor Yellow