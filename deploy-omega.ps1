# OMEGA Website Deployment Script - Improved Version
# Deploy to Cloud Server with proper error handling

param(
    [string]$ServerIP = $env:OMEGA_SERVER_IP,
    [string]$Username = $env:OMEGA_SERVER_USER,
    [string]$Password = $env:OMEGA_SERVER_PASSWORD,
    [string]$Domain = $env:OMEGA_SERVER_DOMAIN
)

$sshKeyPath = $env:OMEGA_SSH_KEY_PATH
$usingKey = [bool]$sshKeyPath

if (-not $ServerIP -or -not $Username -or ((-not $Password) -and -not $usingKey)) {
    Write-Host "❌ Server credentials not set. Please export OMEGA_SERVER_IP, OMEGA_SERVER_USER, and either OMEGA_SERVER_PASSWORD or OMEGA_SSH_KEY_PATH (optionally OMEGA_SERVER_DOMAIN)." -ForegroundColor Red
    exit 1
}

$sshAuthArgs = if ($usingKey) { "-i `"$sshKeyPath`"" } else { "-pw `"$Password`"" }

if (-not $ServerIP -or -not $Username -or -not $Password) {
    Write-Host "❌ Server credentials not set. Please export OMEGA_SERVER_IP, OMEGA_SERVER_USER, OMEGA_SERVER_PASSWORD (and optionally OMEGA_SERVER_DOMAIN)." -ForegroundColor Red
    exit 1
}

Write-Host "🚀 OMEGA Website Deployment (Improved)" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Check if deployment package exists
if (-not (Test-Path "deploy-package")) {
    Write-Host "❌ Deployment package not found! Run deploy.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "📦 Deployment package found" -ForegroundColor Green

# Step 1: Create directories on server first
Write-Host "🔧 Creating directories on server..." -ForegroundColor Yellow

$createDirCommands = @"
mkdir -p /tmp/omega-deploy
mkdir -p /var/www/omega
apt update && apt install -y nginx
systemctl enable nginx
"@

# Create SSH command batch
$sshPrep = @"
@echo off
echo Creating directories on server...
plink -batch $sshAuthArgs $Username@$ServerIP "$createDirCommands"
"@

$sshPrep | Out-File -FilePath "temp-prep.bat" -Encoding ASCII

try {
    Write-Host "📡 Executing server preparation..." -ForegroundColor Yellow
    $prepResult = & cmd /c "temp-prep.bat"
    Write-Host $prepResult
    
    # Step 2: Upload files one by one to avoid issues
    Write-Host "📤 Uploading website files..." -ForegroundColor Yellow
    
    # Upload main files
    $mainFiles = @("index.html", "playground.html", "styles.css", "script.js", "logo.svg", "performance.js", "lang.js")
    
    foreach ($file in $mainFiles) {
        if (Test-Path "deploy-package\$file") {
            Write-Host "   Uploading $file..." -ForegroundColor Gray
            $uploadCmd = "pscp -batch $sshAuthArgs `"deploy-package\$file`" $Username@${ServerIP}:/tmp/omega-deploy/"
            & cmd /c $uploadCmd
        }
    }
    
    # Upload configuration files
    Write-Host "   Uploading configuration files..." -ForegroundColor Gray
    $configFiles = @("omega-nginx.conf", "setup-server.sh")
    foreach ($file in $configFiles) {
        if (Test-Path "deploy-package\$file") {
            $uploadCmd = "pscp -batch $sshAuthArgs `"deploy-package\$file`" $Username@${ServerIP}:/tmp/omega-deploy/"
            & cmd /c $uploadCmd
        }
    }
    
    # Upload docs directory
    if (Test-Path "deploy-package\docs") {
        Write-Host "   Uploading docs directory..." -ForegroundColor Gray
        $uploadCmd = "pscp -batch -r $sshAuthArgs `"deploy-package\docs`" $Username@${ServerIP}:/tmp/omega-deploy/"
        & cmd /c $uploadCmd
    }
    
    Write-Host "✅ Files uploaded successfully!" -ForegroundColor Green
    
    # Step 3: Execute deployment on server
    Write-Host "🚀 Executing deployment on server..." -ForegroundColor Yellow
    
    $deployCommands = @"
cd /tmp/omega-deploy
chmod +x setup-server.sh
./setup-server.sh
cp -r *.html *.css *.js *.svg *.json docs /var/www/omega/ 2>/dev/null || true
chown -R www-data:www-data /var/www/omega
systemctl restart nginx
systemctl status nginx --no-pager
echo "Deployment completed!"
"@
    
    $deployBatch = @"
@echo off
echo Executing deployment...
plink -batch $sshAuthArgs $Username@$ServerIP "$deployCommands"
"@
    
    $deployBatch | Out-File -FilePath "temp-deploy.bat" -Encoding ASCII
    $deployResult = & cmd /c "temp-deploy.bat"
    Write-Host $deployResult
    
    Write-Host "✅ Deployment process completed!" -ForegroundColor Green
    
    # Step 4: Test server response
    Write-Host "🧪 Testing server response..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://$ServerIP" -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Server is responding correctly!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Server responded with status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Could not test server response: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error during deployment: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Clean up temporary files
    @("temp-prep.bat", "temp-deploy.bat") | ForEach-Object {
        if (Test-Path $_) { Remove-Item $_ -Force }
    }
}

Write-Host "`n🎉 OMEGA Website Deployment Summary" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "✅ Server IP: $ServerIP" -ForegroundColor Green
Write-Host "✅ Website files deployed to: /var/www/omega" -ForegroundColor Green
Write-Host "✅ Nginx web server configured and running" -ForegroundColor Green
Write-Host "🌐 Direct IP access: http://$ServerIP" -ForegroundColor White

Write-Host "`n📋 Final Steps (Manual):" -ForegroundColor Cyan
Write-Host "   1. 🌍 Configure DNS A record:" -ForegroundColor White
Write-Host "      Domain: $Domain" -ForegroundColor Gray
Write-Host "      Type: A" -ForegroundColor Gray
Write-Host "      Value: $ServerIP" -ForegroundColor Gray
Write-Host "      TTL: 300 (5 minutes)" -ForegroundColor Gray
Write-Host "`n   2. ⏳ Wait for DNS propagation (5-30 minutes)" -ForegroundColor White
Write-Host "`n   3. 🧪 Test the website:" -ForegroundColor White
Write-Host "      http://$Domain" -ForegroundColor Gray
Write-Host "      http://$ServerIP (direct IP)" -ForegroundColor Gray
Write-Host "`n   4. 🔒 Optional: Setup SSL certificate" -ForegroundColor White
Write-Host "      Use Let's Encrypt: certbot --nginx -d $Domain" -ForegroundColor Gray

Write-Host "`n🚀 OMEGA Website is now live!" -ForegroundColor Green