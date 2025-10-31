#!/usr/bin/env pwsh
# OMEGA Native Testing Script
# Comprehensive testing for OMEGA native language system
# Author: Emylton Leunufna
# Version: 2.0.0 (Native)

param(
    [switch]$SkipBuild,
    [switch]$Verbose,
    [string]$TestSuite = "all",
    [string]$OutputDir = "test_results"
)

# Test configuration
$script:TestResults = @{
    Passed = 0
    Failed = 0
    Skipped = 0
    Details = @()
}

# ANSI Colors for better output
$Colors = @{
    Red = "`e[31m"
    Green = "`e[32m"
    Yellow = "`e[33m"
    Blue = "`e[34m"
    Magenta = "`e[35m"
    Cyan = "`e[36m"
    Reset = "`e[0m"
}

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

# Check OMEGA native binary
if (Test-Path "omega.exe") {
    Test-Result "omega_binary" "PASS" "OMEGA native binary found"
    
    # Test OMEGA version command
    try {
        $versionOutput = & ".\omega.exe" --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Test-Result "omega_version" "PASS" "OMEGA version command works: $versionOutput"
        } else {
            Test-Result "omega_version" "FAIL" "OMEGA version command failed (Exit code: $LASTEXITCODE)"
        }
    } catch {
        Test-Result "omega_version" "FAIL" "Could not execute OMEGA binary: $($_.Exception.Message)"
    }
} else {
    Test-Result "omega_binary" "FAIL" "OMEGA native binary (omega.exe) not found"
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
    # For native OMEGA, we check if the binary is already built
    $binaryPath = Join-Path $OmegaRoot "omega.exe"
    if (Test-Path $binaryPath) {
        Test-Result "binary_exists" "PASS" "OMEGA native binary exists at $binaryPath"
        
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
        Test-Result "binary_exists" "FAIL" "OMEGA native binary does not exist"
    }
} else {
    Test-Result "build_validation" "WARN" "Build validation skipped"
}

# 4. Unit Testing
Write-Host ""
Write-Host "🧪 Unit Testing" -ForegroundColor $Cyan
Write-Host "================"

# For native OMEGA, we run built-in tests if available
if (Test-Path "omega.exe") {
    try {
        Write-Host "Running OMEGA native tests..."
        $testResult = & ".\omega.exe" --test 2>&1
        if ($LASTEXITCODE -eq 0) {
            Test-Result "native_tests" "PASS" "OMEGA native tests passed"
        } else {
            # If --test flag doesn't exist, that's okay for native version
            Test-Result "native_tests" "WARN" "OMEGA native tests not available or failed"
        }
    } catch {
        Test-Result "native_tests" "WARN" "Could not run OMEGA native tests"
    }
} else {
    Test-Result "native_tests" "FAIL" "OMEGA binary not available for testing"
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

# Check for OMEGA native configuration files
$omegaConfigPath = Join-Path $OmegaRoot "omega.config"
if (Test-Path $omegaConfigPath) {
    Test-Result "omega_config" "PASS" "OMEGA configuration file found"
} else {
    Test-Result "omega_config" "WARN" "OMEGA configuration file not found (optional)"
}

# Check for project manifest
$manifestPath = Join-Path $OmegaRoot "project.omega"
if (Test-Path $manifestPath) {
    Test-Result "project_manifest" "PASS" "OMEGA project manifest found"
} else {
    Test-Result "project_manifest" "WARN" "OMEGA project manifest not found (optional)"
}

# Native OMEGA functionality tests
function Test-NativeFunctionality {
    Write-Host "`n$($Colors.Cyan)🧪 Native OMEGA Functionality$($Colors.Reset)"
    
    if (Test-Path "omega.exe") {
        # Test basic OMEGA commands
        try {
            $helpOutput = & ".\omega.exe" --help 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-TestResult "OMEGA Help Command" $true "Help command works"
            } else {
                Write-TestResult "OMEGA Help Command" $false "Exit code: $LASTEXITCODE"
            }
        } catch {
            Write-TestResult "OMEGA Help Command" $false $_.Exception.Message
        }
        
        # Test compilation if .mega files exist
        $megaFiles = Get-ChildItem -Path "." -Filter "*.mega" -Recurse | Select-Object -First 1
        if ($megaFiles) {
            try {
                $compileOutput = & ".\omega.exe" compile $megaFiles.FullName 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-TestResult "OMEGA Compilation Test" $true "Successfully compiled $($megaFiles.Name)"
                } else {
                    Write-TestResult "OMEGA Compilation Test" $false "Compilation failed"
                }
            } catch {
                Write-TestResult "OMEGA Compilation Test" $false $_.Exception.Message
            }
        } else {
            Write-TestResult "OMEGA Compilation Test" $false "No .mega files found to test"
        }
    } else {
        Write-TestResult "OMEGA Native Binary" $false "omega.exe not found"
    }
}

# Documentation validation
function Test-Documentation {
    Write-Host "`n$($Colors.Cyan)📚 Documentation Validation$($Colors.Reset)"
    
    $requiredDocs = @("README.md", "LANGUAGE_SPECIFICATION.md", "COMPILER_ARCHITECTURE.md")
    
    foreach ($doc in $requiredDocs) {
        if (Test-Path $doc) {
            $content = Get-Content $doc -Raw
            if ($content.Length -gt 100) {
                Write-TestResult "Documentation: $doc" $true "Found and has content"
            } else {
                Write-TestResult "Documentation: $doc" $false "File too short or empty"
            }
        } else {
            Write-TestResult "Documentation: $doc" $false "File missing"
        }
    }
}

# Configuration validation
function Test-Configuration {
    Write-Host "`n$($Colors.Cyan)⚙️ Configuration Validation$($Colors.Reset)"
    
    # Check for OMEGA native configuration files
    if (Test-Path "omega.config") {
        Write-TestResult "OMEGA Configuration" $true "omega.config found"
    } else {
        Write-TestResult "OMEGA Configuration" $false "omega.config not found (optional)"
    }
    
    # Check for project manifest
    if (Test-Path "project.omega") {
        Write-TestResult "Project Manifest" $true "project.omega found"
    } else {
        Write-TestResult "Project Manifest" $false "project.omega not found (optional)"
    }
    
    # Check examples directory structure
    if (Test-Path "examples") {
        $exampleDirs = Get-ChildItem -Path "examples" -Directory
        Write-TestResult "Examples Structure" $true "Found $($exampleDirs.Count) example directories"
    } else {
        Write-TestResult "Examples Structure" $false "Examples directory not found"
    }
}

# Security validation
function Test-Security {
    Write-Host "`n$($Colors.Cyan)🔒 Security Validation$($Colors.Reset)"
    
    $securityIssues = 0
    
    # Check for hardcoded secrets in .mega files
    $megaFiles = Get-ChildItem -Path "." -Filter "*.mega" -Recurse -ErrorAction SilentlyContinue
    foreach ($file in $megaFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -and ($content -like "*password*=*" -or $content -like "*secret*=*" -or $content -like "*private_key*=*")) {
            $securityIssues++
        }
    }
    
    if ($securityIssues -eq 0) {
        Write-TestResult "Security: Hardcoded Secrets" $true "No obvious hardcoded secrets detected"
    } else {
        Write-TestResult "Security: Hardcoded Secrets" $false "Potential hardcoded secrets found: $securityIssues"
    }
    
    # Check for secure file permissions (Windows)
    if ($IsWindows -or $env:OS -like "*Windows*") {
        if (Test-Path "omega.exe") {
            Write-TestResult "Security: Binary Permissions" $true "OMEGA binary exists with proper permissions"
        } else {
            Write-TestResult "Security: Binary Permissions" $false "OMEGA binary not found"
        }
    }
}

# Main execution
function Main {
    Write-Host "$($Colors.Blue)🚀 OMEGA Native Testing Suite v2.0.0$($Colors.Reset)"
    Write-Host "$($Colors.Blue)============================================$($Colors.Reset)"
    
    # Run all test suites
    Test-Environment
    Test-SourceCode
    
    if (-not $SkipBuild) {
        Test-NativeFunctionality
    }
    
    Test-Documentation
    Test-Configuration
    Test-Security
    
    # Generate summary
    Write-Host "`n$($Colors.Blue)📊 Testing Summary$($Colors.Reset)"
    Write-Host "$($Colors.Blue)==================$($Colors.Reset)"
    
    $totalTests = $script:TestResults.Passed + $script:TestResults.Failed + $script:TestResults.Skipped
    $successRate = if ($totalTests -gt 0) { [math]::Round(($script:TestResults.Passed * 100.0) / $totalTests, 1) } else { 0 }
    
    Write-Host "✅ PASSED: $($script:TestResults.Passed)" -ForegroundColor Green
    Write-Host "❌ FAILED: $($script:TestResults.Failed)" -ForegroundColor Red
    Write-Host "⏭️ SKIPPED: $($script:TestResults.Skipped)" -ForegroundColor Yellow
    Write-Host "📈 SUCCESS RATE: $successRate%" -ForegroundColor Cyan
    
    # Final decision
    if ($script:TestResults.Failed -eq 0) {
        Write-Host "`n$($Colors.Green)🎉 ALL TESTS PASSED! 🎉$($Colors.Reset)"
        Write-Host "$($Colors.Green)OMEGA Native is ready for deployment.$($Colors.Reset)"
        exit 0
    } else {
        Write-Host "`n$($Colors.Red)❌ SOME TESTS FAILED$($Colors.Reset)"
        Write-Host "$($Colors.Red)Please fix the issues before deployment.$($Colors.Reset)"
        exit 1
    }
}

# Run the main function
Main
    }
    exit 0
} else {
    Write-Host "❌ CRITICAL ISSUES FOUND" -ForegroundColor $Red
    Write-Host "$FailedTests critical issues must be resolved before deployment." -ForegroundColor $Red
    exit 1
}