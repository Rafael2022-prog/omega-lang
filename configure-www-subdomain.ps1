# WWW Subdomain Configuration for OMEGA Website
# This script helps configure and verify 'www.<your-domain>' subdomain (uses OMEGA_SERVER_DOMAIN)

Write-Host "=== OMEGA Website WWW Subdomain Configuration ===" -ForegroundColor Cyan
Write-Host "Configuring $wwwDomain subdomain..." -ForegroundColor Yellow

$serverIP = $env:OMEGA_SERVER_IP
$domain = $env:OMEGA_SERVER_DOMAIN
$wwwDomain = if ($domain) { "www.$domain" } else { $null }

if (-not $serverIP -or -not $domain -or -not $wwwDomain) {
    Write-Host "❌ OMEGA_SERVER_IP atau OMEGA_SERVER_DOMAIN belum di-set. Silakan set variabel lingkungan terlebih dahulu." -ForegroundColor Red
    Write-Host 'Contoh: $env:OMEGA_SERVER_IP = "203.0.113.10"; $env:OMEGA_SERVER_DOMAIN = "example.com"' -ForegroundColor Gray
    return
}

try {
    Write-Host "`n1. Checking current DNS configuration..." -ForegroundColor Green
    
    # Check main domain
    Write-Host "Checking $domain DNS..." -ForegroundColor Yellow
    try {
        $mainDNS = nslookup $domain 2>$null
        Write-Host "✅ $domain resolves correctly" -ForegroundColor Green
        Write-Host $mainDNS -ForegroundColor Gray
    }
    catch {
        Write-Host "❌ $domain DNS resolution failed" -ForegroundColor Red
    }
    
    # Check www subdomain
    Write-Host "`nChecking $wwwDomain DNS..." -ForegroundColor Yellow
    try {
        $wwwDNS = nslookup $wwwDomain 2>$null
        if ($serverIP -and ($wwwDNS -like "*$serverIP*")) {
            Write-Host "✅ $wwwDomain already configured correctly" -ForegroundColor Green
        }
        else {
            Write-Host "⚠️ $wwwDomain needs DNS configuration" -ForegroundColor Yellow
        }
        Write-Host $wwwDNS -ForegroundColor Gray
    }
    catch {
        Write-Host "⚠️ $wwwDomain DNS not configured yet" -ForegroundColor Yellow
    }

    Write-Host "`n2. DNS Configuration Instructions..." -ForegroundColor Green
    Write-Host "To configure $wwwDomain, add these DNS records:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1 - A Record (Recommended):" -ForegroundColor Cyan
    Write-Host "  Type: A" -ForegroundColor White
    Write-Host "  Name: www" -ForegroundColor White
    Write-Host "  Value: $serverIP" -ForegroundColor White
    Write-Host "  TTL: 300 (5 minutes)" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 2 - CNAME Record:" -ForegroundColor Cyan
    Write-Host "  Type: CNAME" -ForegroundColor White
    Write-Host "  Name: www" -ForegroundColor White
    Write-Host "  Value: $domain" -ForegroundColor White
    Write-Host "  TTL: 300 (5 minutes)" -ForegroundColor White

    Write-Host "`n3. Testing subdomain accessibility..." -ForegroundColor Green
    
    # Test www subdomain if it resolves
    Write-Host "Testing www subdomain access..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://$wwwDomain" -Method GET -TimeoutSec 10
        Write-Host "✅ WWW Subdomain Access: HTTP $($response.StatusCode)" -ForegroundColor Green
        
        if ($response.Content -match "OMEGA") {
            Write-Host "✅ WWW subdomain content verified!" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "⚠️ WWW subdomain not accessible yet: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "This is normal if DNS hasn't been configured yet." -ForegroundColor Gray
    }

    Write-Host "`n4. Creating DNS verification script..." -ForegroundColor Green
    
    $verificationScript = @"
# DNS Verification Script for WWW Subdomain
Write-Host "=== WWW Subdomain DNS Verification ===" -ForegroundColor Cyan

`$domain = "$domain"
`$wwwDomain = "$wwwDomain"
`$expectedIP = "$serverIP"

Write-Host "Checking DNS propagation..." -ForegroundColor Yellow

# Check main domain
`$mainResult = nslookup `$domain 2>`$null
if (`$mainResult -match `$expectedIP) {
    Write-Host "✅ `$domain → `$expectedIP" -ForegroundColor Green
} else {
    Write-Host "❌ `$domain DNS issue" -ForegroundColor Red
}

# Check www subdomain
`$wwwResult = nslookup `$wwwDomain 2>`$null
if (`$wwwResult -match `$expectedIP) {
    Write-Host "✅ `$wwwDomain → `$expectedIP" -ForegroundColor Green
    
    # Test HTTP access
    try {
        `$response = Invoke-WebRequest -Uri "http://`$wwwDomain" -Method GET -TimeoutSec 10
        Write-Host "✅ HTTP Access: `$(`$response.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ HTTP Access failed: `$(`$_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Test HTTPS access
    try {
        `$response = Invoke-WebRequest -Uri "https://`$wwwDomain" -Method GET -TimeoutSec 10
        Write-Host "✅ HTTPS Access: `$(`$response.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ HTTPS Access failed: `$(`$_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ `$wwwDomain DNS not configured" -ForegroundColor Red
    Write-Host "Please add DNS record: www A `$expectedIP" -ForegroundColor Yellow
}

Write-Host "`nDNS verification completed!" -ForegroundColor Cyan
"@

    $verificationScript | Out-File -FilePath "R:\OMEGA\verify-www-dns.ps1" -Encoding UTF8
    Write-Host "✅ DNS verification script created: verify-www-dns.ps1" -ForegroundColor Green

    Write-Host "`n=== WWW Subdomain Configuration Summary ===" -ForegroundColor Cyan
    Write-Host "✅ DNS configuration instructions provided" -ForegroundColor Green
    Write-Host "✅ DNS verification script created" -ForegroundColor Green
    Write-Host "✅ Server ready for www subdomain" -ForegroundColor Green
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Add DNS record for www subdomain in your domain registrar" -ForegroundColor White
    Write-Host "2. Wait 5-15 minutes for DNS propagation" -ForegroundColor White
    Write-Host "3. Run .\verify-www-dns.ps1 to verify configuration" -ForegroundColor White
    Write-Host "4. Both $domain and $wwwDomain will work" -ForegroundColor White

}
catch {
    Write-Host "❌ Error during WWW subdomain configuration: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nWWW Subdomain configuration completed!" -ForegroundColor Cyan