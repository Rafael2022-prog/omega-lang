# DNS Verification Script for WWW Subdomain
Write-Host "=== WWW Subdomain DNS Verification ===" -ForegroundColor Cyan

$domain = "omegalang.xyz"
$wwwDomain = "www.omegalang.xyz"
$expectedIP = "103.27.206.177"

Write-Host "Checking DNS propagation..." -ForegroundColor Yellow

# Check main domain
$mainResult = nslookup $domain 2>$null
if ($mainResult -match $expectedIP) {
    Write-Host "✅ $domain → $expectedIP" -ForegroundColor Green
} else {
    Write-Host "❌ $domain DNS issue" -ForegroundColor Red
}

# Check www subdomain
$wwwResult = nslookup $wwwDomain 2>$null
if ($wwwResult -match $expectedIP) {
    Write-Host "✅ $wwwDomain → $expectedIP" -ForegroundColor Green
    
    # Test HTTP access
    try {
        $response = Invoke-WebRequest -Uri "http://$wwwDomain" -Method GET -TimeoutSec 10
        Write-Host "✅ HTTP Access: $($response.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ HTTP Access failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Test HTTPS access
    try {
        $response = Invoke-WebRequest -Uri "https://$wwwDomain" -Method GET -TimeoutSec 10
        Write-Host "✅ HTTPS Access: $($response.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ HTTPS Access failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ $wwwDomain DNS not configured" -ForegroundColor Red
    Write-Host "Please add DNS record: www A $expectedIP" -ForegroundColor Yellow
}

Write-Host "
DNS verification completed!" -ForegroundColor Cyan
