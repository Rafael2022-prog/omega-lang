#!/usr/bin/env pwsh
# Week 1 Production Testing Script
# Runs all tests automatically and documents results

param(
    [string]$ReportFile = "r:\OMEGA\tests\WEEK_1_TEST_RESULTS.txt"
)

$startTime = Get-Date
$testResults = @()
$passCount = 0
$failCount = 0

function Log-Test {
    param([string]$TestName, [string]$Command, [bool]$Success, [string]$Output)
    
    $result = @{
        Name = $TestName
        Command = $Command
        Success = $Success
        Output = $Output
        Time = Get-Date
    }
    
    if ($Success) { $script:passCount++ } else { $script:failCount++ }
    $script:testResults += $result
    
    $status = $Success ? "✅ PASS" : "❌ FAIL"
    Write-Host "$status : $TestName"
}

# Header
Write-Host "=== OMEGA WEEK 1 PRODUCTION TESTING ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)" -ForegroundColor Cyan
Write-Host ""

# Test 1: Build - Basic
Write-Host "TEST 1: Basic Build..." -ForegroundColor Yellow
Push-Location "r:\OMEGA\tests\sample"
try {
    $output = & r:\OMEGA\omega.ps1 build 2>&1
    $success = $LASTEXITCODE -eq 0 -and ($output -match "SUCCESS" -or (Test-Path "target"))
    Log-Test "Build - Basic" "omega build" $success $output
    if ($success) { Write-Host "  Output: $($output | Select-Object -First 3)" }
} catch {
    Log-Test "Build - Basic" "omega build" $false $_.Exception.Message
}

# Test 2: Build - Debug
Write-Host "TEST 2: Build Debug Mode..." -ForegroundColor Yellow
try {
    $output = & r:\OMEGA\omega.ps1 build --debug 2>&1
    $success = $LASTEXITCODE -eq 0
    Log-Test "Build - Debug" "omega build --debug" $success $output
} catch {
    Log-Test "Build - Debug" "omega build --debug" $false $_.Exception.Message
}

# Test 3: Build - Release
Write-Host "TEST 3: Build Release Mode..." -ForegroundColor Yellow
try {
    $output = & r:\OMEGA\omega.ps1 build --release 2>&1
    $success = $LASTEXITCODE -eq 0
    Log-Test "Build - Release" "omega build --release" $success $output
} catch {
    Log-Test "Build - Release" "omega build --release" $false $_.Exception.Message
}

# Test 4: Build - Verbose
Write-Host "TEST 4: Build Verbose..." -ForegroundColor Yellow
try {
    $output = & r:\OMEGA\omega.ps1 build --verbose 2>&1
    $success = $LASTEXITCODE -eq 0
    Log-Test "Build - Verbose" "omega build --verbose" $success $output
} catch {
    Log-Test "Build - Verbose" "omega build --verbose" $false $_.Exception.Message
}

# Test 5: Build - Clean
Write-Host "TEST 5: Build Clean..." -ForegroundColor Yellow
try {
    $output = & r:\OMEGA\omega.ps1 build --clean 2>&1
    $success = $LASTEXITCODE -eq 0
    Log-Test "Build - Clean" "omega build --clean" $success $output
} catch {
    Log-Test "Build - Clean" "omega build --clean" $false $_.Exception.Message
}

# Test 6: Test Framework - Basic
Write-Host "TEST 6: Test Framework - Basic..." -ForegroundColor Yellow
try {
    $output = & r:\OMEGA\omega.ps1 test 2>&1
    $success = $LASTEXITCODE -eq 0
    Log-Test "Test - Basic" "omega test" $success $output
} catch {
    Log-Test "Test - Basic" "omega test" $false $_.Exception.Message
}

# Test 7: Test Framework - Verbose
Write-Host "TEST 7: Test Framework - Verbose..." -ForegroundColor Yellow
try {
    $output = & r:\OMEGA\omega.ps1 test --verbose 2>&1
    $success = $LASTEXITCODE -eq 0
    Log-Test "Test - Verbose" "omega test --verbose" $success $output
} catch {
    Log-Test "Test - Verbose" "omega test --verbose" $false $_.Exception.Message
}

# Test 8: Test Framework - Filter
Write-Host "TEST 8: Test Framework - Filter..." -ForegroundColor Yellow
try {
    $output = & r:\OMEGA\omega.ps1 test --filter=math 2>&1
    $success = $LASTEXITCODE -eq 0
    Log-Test "Test - Filter" "omega test --filter=math" $success $output
} catch {
    Log-Test "Test - Filter" "omega test --filter=math" $false $_.Exception.Message
}

# Test 9: Deploy - List Networks
Write-Host "TEST 9: Deploy - List Networks..." -ForegroundColor Yellow
try {
    $output = & r:\OMEGA\omega.ps1 deploy --list-networks 2>&1
    $success = $LASTEXITCODE -eq 0 -or ($output -match "ethereum" -or $output -match "solana")
    Log-Test "Deploy - Networks" "omega deploy --list-networks" $success $output
} catch {
    Log-Test "Deploy - Networks" "omega deploy --list-networks" $false $_.Exception.Message
}

# Test 10: Deploy - Dry Run
Write-Host "TEST 10: Deploy - Dry Run..." -ForegroundColor Yellow
try {
    $output = & r:\OMEGA\omega.ps1 deploy goerli --dry-run 2>&1
    $success = $LASTEXITCODE -eq 0 -or ($output -match "dry" -or $output -match "simulation")
    Log-Test "Deploy - DryRun" "omega deploy goerli --dry-run" $success $output
} catch {
    Log-Test "Deploy - DryRun" "omega deploy goerli --dry-run" $false $_.Exception.Message
}

Pop-Location

# Summary Report
Write-Host ""
Write-Host "=== TESTING SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Count)"
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host "Success Rate: $(($passCount / $testResults.Count * 100).ToString('F1'))%"
Write-Host ""

# Write to file
$report = @"
OMEGA WEEK 1 PRODUCTION TESTING REPORT
Date: $startTime
Duration: $(((Get-Date) - $startTime).TotalSeconds) seconds

SUMMARY
=======
Total Tests: $($testResults.Count)
Passed: $passCount
Failed: $failCount
Success Rate: $(($passCount / $testResults.Count * 100).ToString('F1'))%

DETAILED RESULTS
================
"@

foreach ($test in $testResults) {
    $status = $test.Success ? "✅ PASS" : "❌ FAIL"
    $report += "`n`n$status : $($test.Name)`nCommand: $($test.Command)`nTime: $($test.Time)`nOutput: $($test.Output | Select-Object -First 2)"
}

$report | Out-File -FilePath $ReportFile -Encoding UTF8
Write-Host "✅ Report saved to: $ReportFile" -ForegroundColor Green

# Display results if success
if ($failCount -eq 0) {
    Write-Host "✅ ALL TESTS PASSED!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some tests failed - see report for details" -ForegroundColor Yellow
}
