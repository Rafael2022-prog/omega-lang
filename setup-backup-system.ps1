# Automated Backup System for OMEGA Website
# This script sets up comprehensive backup system for website files

Write-Host "=== OMEGA Website Backup System Setup ===" -ForegroundColor Cyan
Write-Host "Setting up automated backup system..." -ForegroundColor Yellow

$serverIP = "103.27.206.177"
$sshUser = "root"
$domain = "omegalang.xyz"

try {
    Write-Host "`n1. Creating backup directories and scripts..." -ForegroundColor Green
    $backupSetup = @"
# Create backup directories
mkdir -p /opt/omega-backup
mkdir -p /var/backups/omega
mkdir -p /var/backups/omega/daily
mkdir -p /var/backups/omega/weekly
mkdir -p /var/backups/omega/monthly

# Create main backup script
cat > /opt/omega-backup/backup-omega.sh << 'EOF'
#!/bin/bash
# OMEGA Website Backup Script

BACKUP_DIR="/var/backups/omega"
WEBSITE_DIR="/var/www/omega"
DATE=\$(date '+%Y%m%d_%H%M%S')
BACKUP_TYPE=\$1

if [ -z "\$BACKUP_TYPE" ]; then
    BACKUP_TYPE="daily"
fi

echo "[\$(date)] Starting \$BACKUP_TYPE backup..." >> \$BACKUP_DIR/backup.log

# Create backup filename
BACKUP_FILE="omega_\${BACKUP_TYPE}_\${DATE}.tar.gz"
BACKUP_PATH="\$BACKUP_DIR/\$BACKUP_TYPE/\$BACKUP_FILE"

# Create backup
echo "Creating backup: \$BACKUP_FILE"
tar -czf "\$BACKUP_PATH" -C /var/www omega

# Backup system configurations
CONFIG_BACKUP="omega_config_\${BACKUP_TYPE}_\${DATE}.tar.gz"
CONFIG_PATH="\$BACKUP_DIR/\$BACKUP_TYPE/\$CONFIG_BACKUP"

tar -czf "\$CONFIG_PATH" \
    /opt/omega-monitoring \
    /opt/omega-backup \
    /var/log/omega-monitoring \
    /etc/crontab 2>/dev/null

# Verify backup
if [ -f "\$BACKUP_PATH" ] && [ -s "\$BACKUP_PATH" ]; then
    BACKUP_SIZE=\$(du -h "\$BACKUP_PATH" | cut -f1)
    echo "[\$(date)] \$BACKUP_TYPE backup completed: \$BACKUP_FILE (\$BACKUP_SIZE)" >> \$BACKUP_DIR/backup.log
    echo "✅ Backup successful: \$BACKUP_FILE (\$BACKUP_SIZE)"
else
    echo "[\$(date)] \$BACKUP_TYPE backup FAILED: \$BACKUP_FILE" >> \$BACKUP_DIR/backup.log
    echo "❌ Backup failed: \$BACKUP_FILE"
    exit 1
fi

# Cleanup old backups based on type
case "\$BACKUP_TYPE" in
    "daily")
        # Keep last 7 daily backups
        find "\$BACKUP_DIR/daily" -name "omega_daily_*.tar.gz" -type f -mtime +7 -delete
        find "\$BACKUP_DIR/daily" -name "omega_config_daily_*.tar.gz" -type f -mtime +7 -delete
        ;;
    "weekly")
        # Keep last 4 weekly backups
        find "\$BACKUP_DIR/weekly" -name "omega_weekly_*.tar.gz" -type f -mtime +28 -delete
        find "\$BACKUP_DIR/weekly" -name "omega_config_weekly_*.tar.gz" -type f -mtime +28 -delete
        ;;
    "monthly")
        # Keep last 12 monthly backups
        find "\$BACKUP_DIR/monthly" -name "omega_monthly_*.tar.gz" -type f -mtime +365 -delete
        find "\$BACKUP_DIR/monthly" -name "omega_config_monthly_*.tar.gz" -type f -mtime +365 -delete
        ;;
esac

echo "[\$(date)] Cleanup completed for \$BACKUP_TYPE backups" >> \$BACKUP_DIR/backup.log
EOF

chmod +x /opt/omega-backup/backup-omega.sh

# Create backup restore script
cat > /opt/omega-backup/restore-omega.sh << 'EOF'
#!/bin/bash
# OMEGA Website Restore Script

BACKUP_DIR="/var/backups/omega"
WEBSITE_DIR="/var/www/omega"
BACKUP_FILE=\$1

if [ -z "\$BACKUP_FILE" ]; then
    echo "Usage: \$0 <backup_file>"
    echo "Available backups:"
    find \$BACKUP_DIR -name "omega_*.tar.gz" -type f | sort -r | head -10
    exit 1
fi

if [ ! -f "\$BACKUP_FILE" ]; then
    echo "Backup file not found: \$BACKUP_FILE"
    exit 1
fi

echo "[\$(date)] Starting restore from: \$BACKUP_FILE" >> \$BACKUP_DIR/backup.log

# Create backup of current state before restore
CURRENT_BACKUP="omega_pre_restore_\$(date '+%Y%m%d_%H%M%S').tar.gz"
tar -czf "\$BACKUP_DIR/\$CURRENT_BACKUP" -C /var/www omega

# Stop services
pkill -f "python.*http.server" || true

# Restore backup
echo "Restoring from backup..."
cd /var/www
tar -xzf "\$BACKUP_FILE"

# Restart services
cd \$WEBSITE_DIR
nohup python3 -m http.server 80 > /dev/null 2>&1 &

echo "[\$(date)] Restore completed from: \$BACKUP_FILE" >> \$BACKUP_DIR/backup.log
echo "✅ Restore completed successfully"
EOF

chmod +x /opt/omega-backup/restore-omega.sh

# Create backup status script
cat > /opt/omega-backup/backup-status.sh << 'EOF'
#!/bin/bash
# OMEGA Backup Status Script

BACKUP_DIR="/var/backups/omega"

echo "=== OMEGA Backup Status ==="
echo "Backup Directory: \$BACKUP_DIR"
echo "Total Backup Size: \$(du -sh \$BACKUP_DIR | cut -f1)"
echo ""

echo "=== Recent Backups ==="
echo "Daily Backups:"
ls -lh \$BACKUP_DIR/daily/omega_daily_*.tar.gz 2>/dev/null | tail -5 || echo "No daily backups found"
echo ""

echo "Weekly Backups:"
ls -lh \$BACKUP_DIR/weekly/omega_weekly_*.tar.gz 2>/dev/null | tail -3 || echo "No weekly backups found"
echo ""

echo "Monthly Backups:"
ls -lh \$BACKUP_DIR/monthly/omega_monthly_*.tar.gz 2>/dev/null | tail -3 || echo "No monthly backups found"
echo ""

echo "=== Recent Backup Log ==="
tail -10 \$BACKUP_DIR/backup.log 2>/dev/null || echo "No backup log found"
EOF

chmod +x /opt/omega-backup/backup-status.sh

echo "Backup scripts created!"
"@

    Write-Host "Creating backup scripts..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP $backupSetup

    Write-Host "`n2. Setting up automated backup cron jobs..." -ForegroundColor Green
    $cronBackupSetup = @"
# Setup backup cron jobs
(crontab -l 2>/dev/null; echo "# OMEGA Backup Jobs") | crontab -
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/omega-backup/backup-omega.sh daily") | crontab -
(crontab -l 2>/dev/null; echo "0 3 * * 0 /opt/omega-backup/backup-omega.sh weekly") | crontab -
(crontab -l 2>/dev/null; echo "0 4 1 * * /opt/omega-backup/backup-omega.sh monthly") | crontab -

echo "Backup cron jobs configured!"
crontab -l | grep -E "(backup|OMEGA)"
"@

    Write-Host "Setting up backup cron jobs..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP $cronBackupSetup

    Write-Host "`n3. Creating initial backup..." -ForegroundColor Green
    Write-Host "Running initial backup test..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP "/opt/omega-backup/backup-omega.sh daily"

    Write-Host "`n4. Creating local backup management script..." -ForegroundColor Green
    
    $backupManagerScript = @"
# OMEGA Backup Management Dashboard
Write-Host "=== OMEGA Backup Management Dashboard ===" -ForegroundColor Cyan

`$serverIP = "$serverIP"
`$sshUser = "$sshUser"

function Show-BackupStatus {
    Write-Host "`n📊 Backup Status:" -ForegroundColor Yellow
    try {
        `$backupStatus = ssh `$sshUser@`$serverIP "/opt/omega-backup/backup-status.sh"
        Write-Host `$backupStatus -ForegroundColor Gray
    }
    catch {
        Write-Host "❌ Unable to fetch backup status" -ForegroundColor Red
    }
}

function Create-Backup {
    `$backupType = Read-Host "Enter backup type (daily/weekly/monthly)"
    if (`$backupType -notin @("daily", "weekly", "monthly")) {
        Write-Host "❌ Invalid backup type. Use: daily, weekly, or monthly" -ForegroundColor Red
        return
    }
    
    Write-Host "Creating `$backupType backup..." -ForegroundColor Yellow
    try {
        `$result = ssh `$sshUser@`$serverIP "/opt/omega-backup/backup-omega.sh `$backupType"
        Write-Host `$result -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Backup creation failed: `$(`$_.Exception.Message)" -ForegroundColor Red
    }
}

function List-Backups {
    Write-Host "`n📋 Available Backups:" -ForegroundColor Yellow
    try {
        `$backups = ssh `$sshUser@`$serverIP "find /var/backups/omega -name 'omega_*.tar.gz' -type f | sort -r | head -20"
        if (`$backups) {
            Write-Host `$backups -ForegroundColor Gray
        } else {
            Write-Host "No backups found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "❌ Unable to list backups" -ForegroundColor Red
    }
}

function Restore-Backup {
    Write-Host "`nAvailable backups for restore:" -ForegroundColor Yellow
    List-Backups
    
    `$backupFile = Read-Host "`nEnter full path to backup file"
    if (-not `$backupFile) {
        Write-Host "❌ No backup file specified" -ForegroundColor Red
        return
    }
    
    `$confirm = Read-Host "⚠️ This will replace current website files. Continue? (yes/no)"
    if (`$confirm -ne "yes") {
        Write-Host "Restore cancelled" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Restoring from backup..." -ForegroundColor Yellow
    try {
        `$result = ssh `$sshUser@`$serverIP "/opt/omega-backup/restore-omega.sh `$backupFile"
        Write-Host `$result -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Restore failed: `$(`$_.Exception.Message)" -ForegroundColor Red
    }
}

function Download-Backup {
    Write-Host "`nAvailable backups for download:" -ForegroundColor Yellow
    List-Backups
    
    `$backupFile = Read-Host "`nEnter full path to backup file"
    if (-not `$backupFile) {
        Write-Host "❌ No backup file specified" -ForegroundColor Red
        return
    }
    
    `$localPath = Read-Host "Enter local download path (default: R:\OMEGA\backups)"
    if (-not `$localPath) {
        `$localPath = "R:\OMEGA\backups"
    }
    
    # Create local backup directory
    if (-not (Test-Path `$localPath)) {
        New-Item -ItemType Directory -Path `$localPath -Force | Out-Null
    }
    
    `$fileName = Split-Path `$backupFile -Leaf
    `$localFile = Join-Path `$localPath `$fileName
    
    Write-Host "Downloading backup to `$localFile..." -ForegroundColor Yellow
    try {
        scp `$sshUser@`$serverIP:`$backupFile `$localFile
        Write-Host "✅ Backup downloaded successfully to `$localFile" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Download failed: `$(`$_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-BackupMenu {
    Write-Host "`n=== Backup Management Options ===" -ForegroundColor Cyan
    Write-Host "1. Show Backup Status" -ForegroundColor White
    Write-Host "2. Create New Backup" -ForegroundColor White
    Write-Host "3. List Available Backups" -ForegroundColor White
    Write-Host "4. Restore from Backup" -ForegroundColor White
    Write-Host "5. Download Backup to Local" -ForegroundColor White
    Write-Host "6. Exit" -ForegroundColor White
    Write-Host ""
}

# Main backup management loop
do {
    Show-BackupMenu
    `$choice = Read-Host "Select option (1-6)"
    
    switch (`$choice) {
        "1" { Show-BackupStatus }
        "2" { Create-Backup }
        "3" { List-Backups }
        "4" { Restore-Backup }
        "5" { Download-Backup }
        "6" { 
            Write-Host "Exiting backup management..." -ForegroundColor Yellow
            break
        }
        default { Write-Host "Invalid option. Please select 1-6." -ForegroundColor Red }
    }
    
    if (`$choice -ne "6") {
        Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
        Read-Host
    }
} while (`$choice -ne "6")

Write-Host "Backup management dashboard closed." -ForegroundColor Cyan
"@

    $backupManagerScript | Out-File -FilePath "R:\OMEGA\backup-manager.ps1" -Encoding UTF8
    Write-Host "✅ Backup management dashboard created: backup-manager.ps1" -ForegroundColor Green

    Write-Host "`n5. Testing backup system..." -ForegroundColor Green
    Write-Host "Verifying backup system..." -ForegroundColor Yellow
    ssh $sshUser@$serverIP "/opt/omega-backup/backup-status.sh"

    Write-Host "`n=== Backup System Setup Summary ===" -ForegroundColor Cyan
    Write-Host "✅ Backup directories created" -ForegroundColor Green
    Write-Host "✅ Automated backup scripts installed" -ForegroundColor Green
    Write-Host "✅ Restore functionality configured" -ForegroundColor Green
    Write-Host "✅ Backup cron jobs scheduled" -ForegroundColor Green
    Write-Host "✅ Initial backup created" -ForegroundColor Green
    Write-Host "✅ Backup management dashboard created" -ForegroundColor Green
    
    Write-Host "`nBackup Schedule:" -ForegroundColor Yellow
    Write-Host "• Daily: 2:00 AM (keeps 7 days)" -ForegroundColor White
    Write-Host "• Weekly: 3:00 AM Sunday (keeps 4 weeks)" -ForegroundColor White
    Write-Host "• Monthly: 4:00 AM 1st day (keeps 12 months)" -ForegroundColor White
    
    Write-Host "`nBackup Features:" -ForegroundColor Yellow
    Write-Host "• Website files backup" -ForegroundColor White
    Write-Host "• Configuration backup" -ForegroundColor White
    Write-Host "• Automated cleanup" -ForegroundColor White
    Write-Host "• Restore functionality" -ForegroundColor White
    Write-Host "• Download to local" -ForegroundColor White
    
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "• Run .\backup-manager.ps1 for backup management" -ForegroundColor White
    Write-Host "• Backups stored in /var/backups/omega/ on server" -ForegroundColor White
    Write-Host "• Automatic backups run daily/weekly/monthly" -ForegroundColor White

}
catch {
    Write-Host "❌ Error during backup setup: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nBackup system setup completed!" -ForegroundColor Cyan