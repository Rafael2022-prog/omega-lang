# OMEGA Website Upload Script
# Upload files to server and deploy

param(
    [string]$ServerIP = "103.27.206.177",
    [string]$Username = "root",
    [string]$Password = "!eL3H!Ue^Ik2"
)

Write-Host "🚀 OMEGA Website Upload & Deployment" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Check if deployment package exists
if (-not (Test-Path "deploy-package")) {
    Write-Host "❌ Deployment package not found! Run deploy.ps1 first." -ForegroundColor Red
    exit 1
}

# Check if pscp (PuTTY SCP) is available
$pscpPath = Get-Command pscp -ErrorAction SilentlyContinue
if (-not $pscpPath) {
    Write-Host "❌ pscp (PuTTY SCP) not found!" -ForegroundColor Red
    Write-Host "📥 Please install PuTTY or use alternative method" -ForegroundColor Yellow
    Write-Host "💡 Alternative: Use WinSCP, FileZilla, or manual upload" -ForegroundColor Yellow
    
    # Create manual deployment instructions
    $instructions = @"
📋 Manual Deployment Instructions:
================================

1. Upload files to server:
   - Use WinSCP, FileZilla, or similar SFTP client
   - Server: $ServerIP
   - Username: $Username  
   - Password: $Password
   - Upload all files from ./deploy-package/ to /tmp/omega-deploy/

2. Connect via SSH and run:
   ssh $Username@$ServerIP
   cd /tmp/omega-deploy
   chmod +x setup-server.sh
   ./setup-server.sh
   cp -r * /var/www/omega/
   
3. Configure DNS:
   - Add A record: www.omegalang.xyz -> $ServerIP
   
4. Test website:
   - Visit: http://www.omegalang.xyz
"@
    
    $instructions | Out-File -FilePath "MANUAL_DEPLOYMENT.txt" -Encoding UTF8
    Write-Host "📝 Manual deployment instructions saved to MANUAL_DEPLOYMENT.txt" -ForegroundColor Green
    return
}

Write-Host "📡 Uploading files to server..." -ForegroundColor Yellow

# Create temporary batch file for pscp (to handle password)
$batchContent = @"
@echo off
echo Uploading OMEGA website files...
pscp -r -pw "$Password" deploy-package\* $Username@${ServerIP}:/tmp/omega-deploy/
if %errorlevel% neq 0 (
    echo Upload failed!
    exit /b 1
)
echo Upload completed successfully!
"@

$batchContent | Out-File -FilePath "temp-upload.bat" -Encoding ASCII

# Execute upload
try {
    $result = & cmd /c "temp-upload.bat"
    Write-Host $result
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Files uploaded successfully!" -ForegroundColor Green
        
        # Now execute deployment script on server
        Write-Host "🔧 Executing deployment script on server..." -ForegroundColor Yellow
        
        $deployCommands = @"
cd /tmp/omega-deploy && chmod +x setup-server.sh && ./setup-server.sh && cp -r *.html *.css *.js *.svg docs /var/www/omega/
"@
        
        $sshBatch = @"
@echo off
echo Executing deployment on server...
plink -pw "$Password" $Username@$ServerIP "$deployCommands"
"@
        
        $sshBatch | Out-File -FilePath "temp-deploy.bat" -Encoding ASCII
        $deployResult = & cmd /c "temp-deploy.bat"
        Write-Host $deployResult
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
            Write-Host "🌐 Website should be accessible at: http://www.omegalang.xyz" -ForegroundColor Cyan
        } else {
            Write-Host "⚠️  Deployment may have issues. Check server manually." -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Upload failed!" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error during upload: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Clean up temporary files
    if (Test-Path "temp-upload.bat") { Remove-Item "temp-upload.bat" -Force }
    if (Test-Path "temp-deploy.bat") { Remove-Item "temp-deploy.bat" -Force }
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Configure DNS A record: www.omegalang.xyz -> $ServerIP" -ForegroundColor White
Write-Host "   2. Wait for DNS propagation (5-30 minutes)" -ForegroundColor White  
Write-Host "   3. Test website at http://www.omegalang.xyz" -ForegroundColor White
Write-Host "   4. Consider setting up SSL certificate (Let's Encrypt)" -ForegroundColor White