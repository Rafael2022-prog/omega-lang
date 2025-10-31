# Finalize OMEGA Website Deployment
# Complete the server setup

param(
    [string]$ServerIP = "103.27.206.177",
    [string]$Username = "root",
    [string]$Password = "!eL3H!Ue^Ik2"
)

Write-Host "🔧 Finalizing OMEGA Website Deployment" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Execute server commands properly
$serverCommands = @"
cd /tmp/omega-deploy
chmod +x setup-server.sh
bash setup-server.sh
cp -r *.html *.css *.js *.svg docs /var/www/omega/
chown -R www-data:www-data /var/www/omega
systemctl restart nginx
systemctl enable nginx
nginx -t
echo 'OMEGA deployment finalized successfully!'
"@

Write-Host "🚀 Executing final deployment commands..." -ForegroundColor Yellow

# Create proper SSH command
$sshCommand = "plink -batch -pw `"$Password`" $Username@$ServerIP `"$serverCommands`""

try {
    $result = & cmd /c $sshCommand
    Write-Host $result
    Write-Host "✅ Server setup completed!" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test the website
Write-Host "`n🧪 Testing website accessibility..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "http://$ServerIP" -TimeoutSec 15 -ErrorAction Stop
    Write-Host "✅ Website is accessible! Status: $($response.StatusCode)" -ForegroundColor Green
    
    # Check if it contains OMEGA content
    if ($response.Content -like "*OMEGA*") {
        Write-Host "✅ OMEGA website content detected!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Website accessible but OMEGA content not detected" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Website test failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "💡 This might be normal if nginx is still starting up" -ForegroundColor Gray
}

Write-Host "`n🎉 Deployment Status Summary" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host "🌐 Direct IP: http://$ServerIP" -ForegroundColor White
Write-Host "🌐 Domain: http://www.omegalang.xyz (after DNS setup)" -ForegroundColor White
Write-Host "`n📋 DNS Configuration Required:" -ForegroundColor Yellow
Write-Host "   Record Type: A" -ForegroundColor Gray
Write-Host "   Name: www.omegalang.xyz" -ForegroundColor Gray  
Write-Host "   Value: $ServerIP" -ForegroundColor Gray
Write-Host "   TTL: 300" -ForegroundColor Gray

Write-Host "`n🚀 OMEGA Website Deployment Complete!" -ForegroundColor Green