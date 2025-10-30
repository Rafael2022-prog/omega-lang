# OMEGA Simple Comprehensive Testing Script
param(
    [switch]$SkipBuild,
    [string]$OutputDir = "test_results"
)

$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"

$OmegaRoot = Split-Path -Parent $PSScriptRoot
$TestResultsDir = Join-Path $OmegaRoot $OutputDir
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if (-not (Test-Path $TestResultsDir)) {
    New-Item -ItemType Directory -Path $TestResultsDir -Force | Out-Null
}

Write-Host "🧪 OMEGA Comprehensive Testing Suite" -ForegroundColor $Blue
Write-Host "====================================" -ForegroundColor $Blue
Write-Host "Timestamp: $(Get-Date)"
Write-Host "OMEGA Root: $OmegaRoot"
Write-Host ""

$TotalTests = 0
$PassedTests = 0
$FailedTests = 0
$WarningTests = 0

function Test-Result {
    param([string]$TestName, [string]$Status, [string]$Message)
    
    $script:TotalTests++
    
    switch ($Status) {
        "PASS" {
            Write-Host "✅ [$TestName] $Message" -ForegroundColor $Green
            $script:PassedTests++
        }
        "FAIL" {
            Write-Host "❌ [$TestName] $Message" -ForegroundColor $Red
            $script:FailedTests++
        }
        "WARN" {
            Write-Host "⚠️  [$TestName] $Message" -ForegroundColor $Yellow
            $script:WarningTests++
        }
    }
}

# 1. Environment Validation
Write-Host "🌍 Environment Validation" -ForegroundColor $Cyan
Write-Host "=========================="

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Test-Result "powershell_version" "PASS" "PowerShell version is compatible ($($PSVersionTable.PSVersion))"
} else {
    Test-Result "powershell_version" "FAIL" "PowerShell version is too old ($($PSVersionTable.PSVersion))"
}

# Check Rust
try {
    $rustVersion = rustc --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Test-Result "rust_available" "PASS" "Rust is available ($rustVersion)"
    } else {
        Test-Result "rust_available" "FAIL" "Rust is not available"
    }
} catch {
    Test-Result "rust_available" "FAIL" "Rust is not available"
}

# Check Cargo
try {
    $cargoVersion = cargo --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Test-Result "cargo_available" "PASS" "Cargo is available ($cargoVersion)"
    } else {
        Test-Result "cargo_available" "FAIL" "Cargo is not available"
    }
} catch {
    Test-Result "cargo_available" "FAIL" "Cargo is not available"
}

# 2. Source Code Validation
Write-Host ""
Write-Host "📝 Source Code Validation" -ForegroundColor $Cyan
Write-Host "=========================="

$RequiredFiles = @(
    "Cargo.toml",
    "src\main.mega",
    "src\lexer\lexer.mega",
    "src\parser\parser.mega",
    "src\semantic\analyzer.mega",
    "src\ir\optimizer.mega",
    "src\codegen\codegen.mega"
)

foreach ($file in $RequiredFiles) {
    $filePath = Join-Path $OmegaRoot $file
    if (Test-Path $filePath) {
        Test-Result "file_exists" "PASS" "Required file exists: $file"
    } else {
        Test-Result "file_exists" "FAIL" "Required file missing: $file"
    }
}

# 3. Build System Validation
Write-Host ""
Write-Host "🔨 Build System Validation" -ForegroundColor $Cyan
Write-Host "==========================="

if (-not $SkipBuild) {
    try {
        Write-Host "Performing clean build..."
        cargo clean 2>$null | Out-Null
        $buildResult = cargo build --release 2>&1
        if ($LASTEXITCODE -eq 0) {
            Test-Result "clean_build" "PASS" "Clean build successful"
        } else {
            Test-Result "clean_build" "FAIL" "Clean build failed"
            Write-Host "Build output:" -ForegroundColor $Yellow
            $buildResult | ForEach-Object { Write-Host "  $_" -ForegroundColor $Yellow }
        }
    } catch {
        Test-Result "clean_build" "FAIL" "Build process failed"
    }
    
    # Check binary
    $binaryPath = Join-Path $OmegaRoot "target\release\omega.exe"
    if (Test-Path $binaryPath) {
        Test-Result "binary_exists" "PASS" "Binary exists at $binaryPath"
        
        try {
            $versionOutput = & $binaryPath --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Test-Result "basic_functionality" "PASS" "Basic functionality works: $versionOutput"
            } else {
                Test-Result "basic_functionality" "FAIL" "Basic functionality failed"
            }
        } catch {
            Test-Result "basic_functionality" "FAIL" "Could not execute binary"
        }
    } else {
        Test-Result "binary_exists" "FAIL" "Binary does not exist"
    }
} else {
    Test-Result "build_validation" "WARN" "Build validation skipped"
}

# 4. Unit Testing
Write-Host ""
Write-Host "🧪 Unit Testing" -ForegroundColor $Cyan
Write-Host "================"

try {
    Write-Host "Running unit tests..."
    $testResult = cargo test --release 2>&1
    if ($LASTEXITCODE -eq 0) {
        Test-Result "unit_tests" "PASS" "Unit tests passed"
    } else {
        Test-Result "unit_tests" "FAIL" "Unit tests failed"
        Write-Host "Test output:" -ForegroundColor $Yellow
        $testResult | Select-Object -Last 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor $Yellow }
    }
} catch {
    Test-Result "unit_tests" "FAIL" "Could not run unit tests"
}

# 5. Documentation Check
Write-Host ""
Write-Host "📚 Documentation Check" -ForegroundColor $Cyan
Write-Host "======================="

$DocFiles = @("README.md", "LANGUAGE_SPECIFICATION.md", "COMPILER_ARCHITECTURE.md")
foreach ($doc in $DocFiles) {
    $docPath = Join-Path $OmegaRoot $doc
    if (Test-Path $docPath) {
        $content = Get-Content $docPath -Raw
        $wordCount = ($content -split '\s+').Count
        
        if ($wordCount -gt 100) {
            Test-Result "documentation" "PASS" "Documentation file is substantial: $doc ($wordCount words)"
        } else {
            Test-Result "documentation" "WARN" "Documentation file is short: $doc ($wordCount words)"
        }
    } else {
        Test-Result "documentation" "FAIL" "Documentation file missing: $doc"
    }
    }
}

# 6. Configuration Check
Write-Host ""
Write-Host "⚙️  Configuration Check" -ForegroundColor $Cyan
Write-Host "======================="

$cargoTomlPath = Join-Path $OmegaRoot "Cargo.toml"
if (Test-Path $cargoTomlPath) {
    $cargoContent = Get-Content $cargoTomlPath -Raw
    
    if ($cargoContent -like "*[package]*") {
        Test-Result "cargo_package" "PASS" "Cargo.toml has package section"
    } else {
        Test-Result "cargo_package" "FAIL" "Cargo.toml missing package section"
    }
    
    if ($cargoContent -like "*[dependencies]*") {
        Test-Result "cargo_deps" "PASS" "Cargo.toml has dependencies section"
    } else {
        Test-Result "cargo_deps" "WARN" "Cargo.toml missing dependencies section"
    }
} else {
    Test-Result "cargo_toml" "FAIL" "Cargo.toml not found"
}

# 7. Security Check
Write-Host ""
Write-Host "🔒 Security Check" -ForegroundColor $Cyan
Write-Host "=================="

# Simple security checks
$securityIssues = 0

# Check for common security patterns
Get-ChildItem -Path (Join-Path $OmegaRoot "src") -Recurse -Filter "*.mega" -ErrorAction SilentlyContinue | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and ($content -like "*password*=*" -or $content -like "*secret*=*" -or $content -like "*key*=*")) {
        $securityIssues++
    }
}

if ($securityIssues -eq 0) {
    Test-Result "security_secrets" "PASS" "No obvious hardcoded secrets detected"
} else {
    Test-Result "security_secrets" "WARN" "Potential hardcoded secrets found: $securityIssues"
}

# Generate Summary
Write-Host ""
Write-Host "📊 Testing Summary" -ForegroundColor $Blue
Write-Host "==================" -ForegroundColor $Blue

Write-Host "✅ PASSED: $PassedTests" -ForegroundColor $Green
Write-Host "⚠️  WARNINGS: $WarningTests" -ForegroundColor $Yellow
Write-Host "❌ FAILED: $FailedTests" -ForegroundColor $Red

if ($TotalTests -gt 0) {
    $successRate = [math]::Round(($PassedTests * 100.0) / $TotalTests, 1)
    Write-Host "📈 SUCCESS RATE: $successRate%" -ForegroundColor $Cyan
}

Write-Host ""

# Final Decision
if ($FailedTests -eq 0) {
    Write-Host "🎉 ALL CRITICAL TESTS PASSED! 🎉" -ForegroundColor $Green
    Write-Host "OMEGA is ready for deployment." -ForegroundColor $Green
    if ($WarningTests -gt 0) {
        Write-Host "Note: $WarningTests warnings found but do not block deployment." -ForegroundColor $Yellow
    }
    exit 0
} else {
    Write-Host "❌ CRITICAL ISSUES FOUND" -ForegroundColor $Red
    Write-Host "$FailedTests critical issues must be resolved before deployment." -ForegroundColor $Red
    exit 1
}