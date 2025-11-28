# OMEGA Quick Production Check
# Simple verification script for production readiness

param([switch]$Verbose)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OMEGA Production Readiness Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$total = 0

function Check($Name, $Condition) {
    $script:total++
    if ($Condition) {
        Write-Host "  [OK] $Name" -ForegroundColor Green
        $script:passed++
        return $true
    } else {
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        return $false
    }
}

# 1. Core Compiler
Write-Host "1. Core Compiler Components" -ForegroundColor Yellow
Check "Lexer" (Test-Path "src/lexer/lexer.mega")
Check "Parser" (Test-Path "src/parser/parser.mega")
Check "Semantic Analyzer" (Test-Path "src/semantic/analyzer.mega")
Check "IR Generator" (Test-Path "src/ir/ir.mega")
Check "Code Generator" (Test-Path "src/codegen/codegen.mega")
Check "Optimizer" (Test-Path "src/optimizer/optimizer_core.mega")

# 2. CLI Commands
Write-Host ""
Write-Host "2. CLI Commands" -ForegroundColor Yellow
Check "Build Command" (Test-Path "src/commands/build.mega")
Check "Test Command" (Test-Path "src/commands/test.mega")
Check "Deploy Command" (Test-Path "src/commands/deploy.mega")

# 3. Test Suites
Write-Host ""
Write-Host "3. Test Suites" -ForegroundColor Yellow
Check "Lexer Tests" (Test-Path "tests/lexer_tests.mega")
Check "Parser Tests" (Test-Path "tests/parser_tests.mega")
Check "Semantic Tests" (Test-Path "tests/semantic_tests.mega")
Check "Integration Tests" (Test-Path "tests/integration_tests.mega")

# 4. Security
Write-Host ""
Write-Host "4. Security Modules" -ForegroundColor Yellow
Check "Input Validation" (Test-Path "src/security/input_validation.mega")
Check "Memory Safety" (Test-Path "src/security/memory_safety.mega")
Check "Security Auditor" (Test-Path "src/security/security_auditor.mega")

# 5. Build System
Write-Host ""
Write-Host "5. Build System" -ForegroundColor Yellow
Check "Compiler Executable" (Test-Path "omega.exe")
Check "Bootstrap Script" (Test-Path "bootstrap.mega")
Check "Example Contract" (Test-Path "examples/simple_token.omega")

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
$pct = [math]::Round(($passed / $total) * 100)
$status = if ($pct -ge 80) { "READY" } elseif ($pct -ge 60) { "PARTIAL" } else { "NOT READY" }
$color = if ($pct -ge 80) { "Green" } elseif ($pct -ge 60) { "Yellow" } else { "Red" }

Write-Host "  Result: $passed/$total checks passed ($pct%)" -ForegroundColor $color
Write-Host "  Status: $status" -ForegroundColor $color
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Next Steps
if ($pct -lt 100) {
    Write-Host "Next Steps:" -ForegroundColor White
    Write-Host "  1. Run: .\omega.exe compile examples/simple_token.omega" -ForegroundColor Gray
    Write-Host "  2. Get testnet tokens: https://sepoliafaucet.com" -ForegroundColor Gray
    Write-Host "  3. Deploy: .\omega.exe deploy sepolia --contract=..." -ForegroundColor Gray
    Write-Host ""
}

exit $(if ($pct -ge 80) { 0 } else { 1 })
