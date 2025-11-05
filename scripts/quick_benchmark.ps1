# OMEGA Quick Performance Benchmark
# Simple benchmark to verify no performance regression after refactoring

Write-Host "=== OMEGA Quick Performance Benchmark ===" -ForegroundColor Cyan
Write-Host "Testing basic performance metrics..." -ForegroundColor Yellow
Write-Host ""

# Add project root for resolving paths
$OmegaRoot = Split-Path -Parent $PSScriptRoot

# Test 1: Build Performance
Write-Host "1. Testing Build Performance..." -ForegroundColor Green
$buildStart = Get-Date
try {
    # Build using native .mega build script
    $buildResult = & "$OmegaRoot\build_omega_native.ps1" 2>&1
    $buildEnd = Get-Date
    $buildTime = ($buildEnd - $buildStart).TotalSeconds
    
    if ($LASTEXITCODE -eq 0 -or ($buildResult -match "Build completed")) {
        Write-Host "   ✅ Build successful in $([math]::Round($buildTime, 2)) seconds" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Build may have warnings or failed" -ForegroundColor Red
        Write-Host "   Output: $buildResult" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Build error: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Binary Size
Write-Host "2. Testing Binary Size..." -ForegroundColor Green
$binaryPath = Join-Path $OmegaRoot "omega"
if (Test-Path $binaryPath) {
    $binarySize = (Get-Item $binaryPath).Length
    $binarySizeMB = [math]::Round($binarySize / 1MB, 2)
    Write-Host "   ✅ Binary size: $binarySizeMB MB" -ForegroundColor Green
} else {
    Write-Host "   ❌ Binary not found at $binaryPath" -ForegroundColor Red
    exit 1
}

# Test 3: Runtime Performance
Write-Host "3. Testing Runtime Performance..." -ForegroundColor Green
$runtimeStart = Get-Date
try {
    $versionResult = & "$binaryPath" --version 2>&1
    $runtimeEnd = Get-Date
    $runtimeTime = ($runtimeEnd - $runtimeStart).TotalMilliseconds
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Runtime execution in $([math]::Round($runtimeTime, 2)) ms" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Runtime failed" -ForegroundColor Red
        Write-Host "   Error: $versionResult" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Runtime error: $_" -ForegroundColor Red
    exit 1
}

# Test 4: Help Command Performance
Write-Host "4. Testing Help Command Performance..." -ForegroundColor Green
$helpStart = Get-Date
try {
    $helpResult = & "$binaryPath" --help 2>&1
    $helpEnd = Get-Date
    $helpTime = ($helpEnd - $helpStart).TotalMilliseconds
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Help command in $([math]::Round($helpTime, 2)) ms" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Help command failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Help command error: $_" -ForegroundColor Red
    exit 1
}

# Summary
Write-Host ""
Write-Host "=== Benchmark Summary ===" -ForegroundColor Cyan
Write-Host "Build Time:      $([math]::Round($buildTime, 2)) seconds" -ForegroundColor White
Write-Host "Binary Size:     $binarySizeMB MB" -ForegroundColor White
Write-Host "Version Time:    $([math]::Round($runtimeTime, 2)) ms" -ForegroundColor White
Write-Host "Help Time:       $([math]::Round($helpTime, 2)) ms" -ForegroundColor White
Write-Host ""

# Performance Assessment
$overallGood = $true
if ($buildTime -gt 10) {
    Write-Host "⚠️  Build time seems slow (>10s)" -ForegroundColor Yellow
    $overallGood = $false
}
if ($binarySizeMB -gt 50) {
    Write-Host "⚠️  Binary size seems large (>50MB)" -ForegroundColor Yellow
    $overallGood = $false
}
if ($runtimeTime -gt 1000) {
    Write-Host "⚠️  Runtime seems slow (>1000ms)" -ForegroundColor Yellow
    $overallGood = $false
}

if ($overallGood) {
    Write-Host "✅ All performance metrics look good!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some performance metrics need attention" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Benchmark completed successfully!" -ForegroundColor Cyan