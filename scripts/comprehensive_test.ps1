# OMEGA Comprehensive Testing Script for Windows
# PowerShell version of comprehensive validation

param(
    [switch]$SkipBuild,
    [switch]$SkipSecurity,
    [switch]$SkipPerformance,
    [string]$OutputDir = "test_results"
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"

# Configuration
$OmegaRoot = Split-Path -Parent $PSScriptRoot
$TestResultsDir = Join-Path $OmegaRoot $OutputDir
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile = Join-Path $TestResultsDir "comprehensive_test_$Timestamp.json"

# Create results directory
if (-not (Test-Path $TestResultsDir)) {
    New-Item -ItemType Directory -Path $TestResultsDir -Force | Out-Null
}

Write-Host "🧪 OMEGA Comprehensive Testing Suite" -ForegroundColor $Blue
Write-Host "====================================" -ForegroundColor $Blue
Write-Host "Timestamp: $(Get-Date)"
Write-Host "OMEGA Root: $OmegaRoot"
Write-Host "Report File: $ReportFile"
Write-Host ""

# Initialize report
$Report = @{
    test_timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    omega_version = "1.0.0"
    environment = "windows"
    test_results = @{}
}

# Global counters
$TotalTests = 0
$PassedTests = 0
$FailedTests = 0
$WarningTests = 0
$SkippedTests = 0

# Function to log test results
function Log-Test {
    param(
        [string]$TestName,
        [string]$Status,
        [string]$Message,
        [string]$Details = ""
    )
    
    $global:TotalTests++
    
    switch ($Status) {
        "PASS" {
            Write-Host "✅ [$TestName] $Message" -ForegroundColor $Green
            $global:PassedTests++
        }
        "FAIL" {
            Write-Host "❌ [$TestName] $Message" -ForegroundColor $Red
            $global:FailedTests++
        }
        "WARN" {
            Write-Host "⚠️  [$TestName] $Message" -ForegroundColor $Yellow
            $global:WarningTests++
        }
        "SKIP" {
            Write-Host "⏭️  [$TestName] $Message" -ForegroundColor $Blue
            $global:SkippedTests++
        }
    }
    
    $Report.test_results[$TestName] = @{
        status = $Status
        message = $Message
        details = $Details
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
}

# 1. Environment Validation
Write-Host "🌍 Environment Validation" -ForegroundColor $Cyan
Write-Host "=========================="

# Check PowerShell version
$PSVersion = $PSVersionTable.PSVersion.ToString()
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Log-Test "powershell_version" "PASS" "PowerShell version is compatible" $PSVersion
} else {
    Log-Test "powershell_version" "FAIL" "PowerShell version is too old" $PSVersion
}

# Check required tools
$RequiredTools = @("cargo", "rustc", "git")
foreach ($tool in $RequiredTools) {
    try {
        $version = & $tool --version 2>$null | Select-Object -First 1
        if ($LASTEXITCODE -eq 0) {
            Log-Test "tool_$tool" "PASS" "$tool is available" $version
        } else {
            Log-Test "tool_$tool" "FAIL" "$tool is not available"
        }
    } catch {
        Log-Test "tool_$tool" "FAIL" "$tool is not available"
    }
}

# Check Rust version
try {
    $rustVersion = rustc --version | ForEach-Object { ($_ -split ' ')[1] }
    if ($rustVersion -match '^1\.(7[0-9]|[8-9][0-9]|[1-9][0-9][0-9])') {
        Log-Test "rust_version" "PASS" "Rust version is compatible" $rustVersion
    } else {
        Log-Test "rust_version" "FAIL" "Rust version is too old" $rustVersion
    }
} catch {
    Log-Test "rust_version" "FAIL" "Could not determine Rust version"
}

# 2. Source Code Validation
Write-Host "📝 Source Code Validation" -ForegroundColor $Cyan
Write-Host "=========================="

# Check if all required files exist
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
        Log-Test "file_$($file -replace '\\', '_')" "PASS" "Required file exists" $file
    } else {
        Log-Test "file_$($file -replace '\\', '_')" "FAIL" "Required file missing" $file
    }
}

# Check for TODO/FIXME comments
try {
    $todoCount = 0
    Get-ChildItem -Path (Join-Path $OmegaRoot "src") -Recurse -Filter "*.mega" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $todoCount += ([regex]::Matches($content, "TODO|FIXME|XXX")).Count
    }
    
    if ($todoCount -eq 0) {
        Log-Test "code_todos" "PASS" "No TODO/FIXME comments found"
    } elseif ($todoCount -lt 5) {
        Log-Test "code_todos" "WARN" "$todoCount TODO/FIXME comments found"
    } else {
        Log-Test "code_todos" "FAIL" "Too many TODO/FIXME comments: $todoCount"
    }
} catch {
    Log-Test "code_todos" "SKIP" "Could not analyze TODO comments"
}

# 3. Build System Validation
Write-Host "🔨 Build System Validation" -ForegroundColor $Cyan
Write-Host "==========================="

if (-not $SkipBuild) {
    # Clean build test
    try {
        Write-Host "Performing clean build..."
        cargo clean 2>$null
        $buildOutput = cargo build --release 2>&1
        if ($LASTEXITCODE -eq 0) {
            Log-Test "clean_build" "PASS" "Clean build successful"
        } else {
            Log-Test "clean_build" "FAIL" "Clean build failed" ($buildOutput -join "`n")
        }
    } catch {
        Log-Test "clean_build" "FAIL" "Build process failed"
    }
    
    # Check binary exists and test basic functionality
    $binaryPath = Join-Path $OmegaRoot "target\release\omega.exe"
    if (Test-Path $binaryPath) {
        Log-Test "binary_exists" "PASS" "Binary exists"
        
        try {
            $versionOutput = & $binaryPath --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Log-Test "basic_functionality" "PASS" "Basic functionality works" $versionOutput
            } else {
                Log-Test "basic_functionality" "FAIL" "Basic functionality failed"
            }
        } catch {
            Log-Test "basic_functionality" "FAIL" "Could not execute binary"
        }
    } else {
        Log-Test "binary_exists" "FAIL" "Binary does not exist"
    }
} else {
    Log-Test "build_validation" "SKIP" "Build validation skipped"
}

# 4. Unit Testing
Write-Host "🧪 Unit Testing" -ForegroundColor $Cyan
Write-Host "================"

try {
    Write-Host "Running unit tests..."
    $testOutput = cargo test --release 2>&1
    if ($LASTEXITCODE -eq 0) {
        $testResults = $testOutput | Where-Object { $_ -match "test result:" } | Select-Object -Last 1
        Log-Test "unit_tests" "PASS" "Unit tests passed" $testResults
    } else {
        Log-Test "unit_tests" "FAIL" "Unit tests failed" ($testOutput -join "`n")
    }
} catch {
    Log-Test "unit_tests" "FAIL" "Could not run unit tests"
}

# 5. Integration Testing
Write-Host "🔄 Integration Testing" -ForegroundColor $Cyan
Write-Host "======================"

# Create test directory
$IntegrationTestDir = Join-Path $TestResultsDir "integration_test"
if (-not (Test-Path $IntegrationTestDir)) {
    New-Item -ItemType Directory -Path $IntegrationTestDir -Force | Out-Null
}

# Create test contract
$TestContract = @"
blockchain IntegrationTest {
    state {
        uint256 test_value;
        mapping(address => uint256) test_balances;
        string test_name;
    }
    
    constructor(string memory name) {
        test_name = name;
        test_value = 42;
    }
    
    function set_test_value(uint256 new_value) public {
        test_value = new_value;
    }
    
    function get_test_value() public view returns (uint256) {
        return test_value;
    }
    
    function get_test_name() public view returns (string memory) {
        return test_name;
    }
}
"@

$TestContractPath = Join-Path $IntegrationTestDir "integration_test.omega"
$TestContract | Out-File -FilePath $TestContractPath -Encoding UTF8

if (-not $SkipBuild -and (Test-Path $binaryPath)) {
    # Test compilation for different targets
    $targets = @("evm", "solana")
    foreach ($target in $targets) {
        try {
            Write-Host "Testing compilation for $target target..."
            $compileOutput = & $binaryPath compile $TestContractPath --target $target 2>&1
            if ($LASTEXITCODE -eq 0) {
                Log-Test "integration_$target" "PASS" "Integration test passed for $target"
            } else {
                Log-Test "integration_$target" "FAIL" "Integration test failed for $target" ($compileOutput -join "`n")
            }
        } catch {
            Log-Test "integration_$target" "FAIL" "Could not test $target compilation"
        }
    }
} else {
    Log-Test "integration_tests" "SKIP" "Integration tests skipped (no binary)"
}

# 6. Performance Testing
Write-Host "⚡ Performance Testing" -ForegroundColor $Cyan
Write-Host "======================"

if (-not $SkipPerformance -and (Test-Path $binaryPath)) {
    # Simple performance test
    try {
        Write-Host "Running performance test..."
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        & $binaryPath compile $TestContractPath --target evm 2>$null
        $stopwatch.Stop()
        
        $compilationTime = $stopwatch.ElapsedMilliseconds / 1000.0
        if ($compilationTime -lt 10.0) {
            Log-Test "performance_compilation" "PASS" "Compilation performance is good" "$compilationTime seconds"
        } elseif ($compilationTime -lt 30.0) {
            Log-Test "performance_compilation" "WARN" "Compilation performance is acceptable" "$compilationTime seconds"
        } else {
            Log-Test "performance_compilation" "FAIL" "Compilation performance is poor" "$compilationTime seconds"
        }
    } catch {
        Log-Test "performance_compilation" "SKIP" "Could not measure compilation performance"
    }
    
    # Binary size check
    if (Test-Path $binaryPath) {
        $binarySize = (Get-Item $binaryPath).Length
        $binarySizeMB = [math]::Round($binarySize / 1MB, 2)
        
        if ($binarySizeMB -lt 50) {
            Log-Test "binary_size" "PASS" "Binary size is reasonable" "$binarySizeMB MB"
        } elseif ($binarySizeMB -lt 100) {
            Log-Test "binary_size" "WARN" "Binary size is large" "$binarySizeMB MB"
        } else {
            Log-Test "binary_size" "FAIL" "Binary size is too large" "$binarySizeMB MB"
        }
    }
} else {
    Log-Test "performance_tests" "SKIP" "Performance tests skipped"
}

# 7. Security Testing
Write-Host "🔒 Security Testing" -ForegroundColor $Cyan
Write-Host "==================="

if (-not $SkipSecurity) {
    # Check for potential security issues
    try {
        $securityIssues = 0
        
        # Check for hardcoded secrets
        Get-ChildItem -Path (Join-Path $OmegaRoot "src") -Recurse -Filter "*.mega" | ForEach-Object {
            $content = Get-Content $_.FullName -Raw
            if ($content -match "(password|secret|key|token|api_key)\s*=\s*[`"'][^`"']{8,}") {
                $securityIssues++
            }
        }
        
        if ($securityIssues -eq 0) {
            Log-Test "security_secrets" "PASS" "No hardcoded secrets detected"
        } else {
            Log-Test "security_secrets" "FAIL" "Potential hardcoded secrets found" "$securityIssues issues"
        }
        
        # Check Cargo.toml for security settings
        $cargoTomlPath = Join-Path $OmegaRoot "Cargo.toml"
        if (Test-Path $cargoTomlPath) {
            $cargoContent = Get-Content $cargoTomlPath -Raw
            $securityConfigs = 0
            
            if ($cargoContent -match 'overflow-checks\s*=\s*true') { $securityConfigs++ }
            if ($cargoContent -match 'panic\s*=\s*"abort"') { $securityConfigs++ }
            
            if ($securityConfigs -ge 1) {
                Log-Test "security_config" "PASS" "Security configurations found" "$securityConfigs configs"
            } else {
                Log-Test "security_config" "WARN" "Missing security configurations"
            }
        }
    } catch {
        Log-Test "security_analysis" "SKIP" "Could not perform security analysis"
    }
} else {
    Log-Test "security_tests" "SKIP" "Security tests skipped"
}

# 8. Documentation Validation
Write-Host "📚 Documentation Validation" -ForegroundColor $Cyan
Write-Host "============================"

$DocFiles = @("README.md", "LANGUAGE_SPECIFICATION.md", "COMPILER_ARCHITECTURE.md")
foreach ($doc in $DocFiles) {
    $docPath = Join-Path $OmegaRoot $doc
    if (Test-Path $docPath) {
        $content = Get-Content $docPath -Raw
        $wordCount = ($content -split '\s+').Count
        
        if ($wordCount -gt 100) {
            Log-Test "doc_$($doc -replace '\.', '_')" "PASS" "Documentation file is substantial" "$wordCount words"
        } else {
            Log-Test "doc_$($doc -replace '\.', '_')" "WARN" "Documentation file is too short" "$wordCount words"
        }
    } else {
        Log-Test "doc_$($doc -replace '\.', '_')" "FAIL" "Documentation file missing" $doc
    }
}

# 9. Configuration Validation
Write-Host "⚙️  Configuration Validation" -ForegroundColor $Cyan
Write-Host "============================"

# Check Cargo.toml structure
$cargoTomlPath = Join-Path $OmegaRoot "Cargo.toml"
if (Test-Path $cargoTomlPath) {
    try {
        $cargoContent = Get-Content $cargoTomlPath -Raw
        
        # Check required sections
        $requiredSections = @('\[package\]', '\[dependencies\]')
        $missingSections = 0
        
        foreach ($section in $requiredSections) {
            if (-not ($cargoContent -match $section)) {
                $missingSections++
            }
        }
        
        if ($missingSections -eq 0) {
            Log-Test "cargo_structure" "PASS" "Cargo.toml structure is valid"
        } else {
            Log-Test "cargo_structure" "FAIL" "Cargo.toml missing required sections" "$missingSections missing"
        }
    } catch {
        Log-Test "cargo_structure" "FAIL" "Could not validate Cargo.toml"
    }
} else {
    Log-Test "cargo_structure" "FAIL" "Cargo.toml not found"
}

# Save report
try {
    $Report.summary = @{
        total_tests = $TotalTests
        passed = $PassedTests
        failed = $FailedTests
        warnings = $WarningTests
        skipped = $SkippedTests
        success_rate = if ($TotalTests -gt 0) { [math]::Round(($PassedTests * 100.0) / $TotalTests, 2) } else { 0 }
    }
    
    $Report.test_ready = ($FailedTests -eq 0)
    $Report.test_completed = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    
    $Report | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportFile -Encoding UTF8
} catch {
    Write-Host "Warning: Could not save detailed report" -ForegroundColor $Yellow
}

# Generate final summary
Write-Host ""
Write-Host "📊 Comprehensive Testing Summary" -ForegroundColor $Blue
Write-Host "=================================" -ForegroundColor $Blue

Write-Host "✅ PASSED: $PassedTests" -ForegroundColor $Green
Write-Host "⚠️  WARNINGS: $WarningTests" -ForegroundColor $Yellow
Write-Host "❌ FAILED: $FailedTests" -ForegroundColor $Red
Write-Host "⏭️  SKIPPED: $SkippedTests" -ForegroundColor $Blue

if ($TotalTests -gt 0) {
    $successRate = [math]::Round(($PassedTests * 100.0) / $TotalTests, 1)
    Write-Host "📈 SUCCESS RATE: $successRate%" -ForegroundColor $Cyan
}

Write-Host ""
Write-Host "Detailed test report saved to: $ReportFile"

# Final decision
if ($FailedTests -eq 0) {
    Write-Host ""
    Write-Host "🎉 ALL TESTS PASSED! 🎉" -ForegroundColor $Green
    Write-Host "OMEGA is ready for the next phase." -ForegroundColor $Green
    if ($WarningTests -gt 0) {
    Write-Host "Note: $WarningTests warnings were found but do not block progress." -ForegroundColor $Yellow
    }
    exit 0
} else {
    Write-Host ""
    Write-Host "❌ TESTING FAILED" -ForegroundColor $Red
    Write-Host "$FailedTests critical issues must be resolved." -ForegroundColor $Red
    exit 1
}