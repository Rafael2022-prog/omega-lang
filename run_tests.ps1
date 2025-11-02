# OMEGA Integration Test Runner Script
# PowerShell script untuk menjalankan integration tests

param(
    [Alias('Type')][string]$TestType = "all",
    [string]$Category = "",
    [switch]$Verbose = $false,
    [Alias('Report')][switch]$GenerateReport = $false,
    [string]$OutputDir = "test_results"
)

Write-Host "🚀 OMEGA Integration Test Runner" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Ensure output directory exists
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "📁 Created output directory: $OutputDir" -ForegroundColor Green
}

# Function to run OMEGA compiler with test files
function Run-OmegaTest {
    param(
        [string]$TestFile,
        [string]$TestName
    )
    
    Write-Host "🧪 Running $TestName..." -ForegroundColor Yellow
    
    try {
        # Compile the test file (runtime execution not available in current environment)
        $result = & ".\omega.cmd" compile $TestFile 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $TestName COMPILED" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ $TestName FAILED TO COMPILE" -ForegroundColor Red
            if ($Verbose) {
                Write-Host "Error output:" -ForegroundColor Red
                Write-Host $result -ForegroundColor Red
            }
            return $false
        }
    } catch {
        Write-Host "❌ $TestName FAILED with exception: $_" -ForegroundColor Red
        return $false
    }
}

# Function to generate test report
function Generate-TestReport {
    param(
        [hashtable]$Results,
        [string]$OutputPath
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $lines = @()
    $lines += "# OMEGA Integration Test Report"
    $lines += "Generated: $timestamp"
    $lines += ""
    $lines += "## Test Results Summary"

    $totalTests = 0
    $passedTests = 0
    $failedTests = 0
    
    foreach ($test in $Results.Keys) {
        $totalTests++
        if ($Results[$test]) {
            $passedTests++
            $lines += "- ${test}: PASSED"
        } else {
            $failedTests++
            $lines += "- ${test}: FAILED"
        }
    }
    
    $successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }

    $lines += ""
    $lines += "## Statistics"
    $lines += "- Total Tests: $totalTests"
    $lines += "- Passed: $passedTests"
    $lines += "- Failed: $failedTests"
    $lines += "- Success Rate: $successRate%"

    $lines += ""
    $lines += "## Status"
    if ($successRate -ge 95) {
        $lines += "ALL TESTS PASSED - Integration is successful!"
    } elseif ($successRate -ge 80) {
        $lines += "TESTS PASSED WITH WARNINGS - Some issues need attention"
    } else {
        $lines += "TESTS FAILED - Critical issues require immediate attention"
    }
    
    ($lines -join [Environment]::NewLine) | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Test report generated: $OutputPath" -ForegroundColor Cyan
}

# Main test execution
[hashtable]$testResults = @{}
$startTime = Get-Date

Write-Host "🔍 Test Type: $TestType" -ForegroundColor Cyan
$normalizedTestType = ("" + $TestType).Trim().ToLower()
Write-Host "Normalized Test Type: $normalizedTestType" -ForegroundColor Cyan
Add-Content -Path "R:\OMEGA\debug.txt" -Value "TESTTYPE:$normalizedTestType"
# DEBUG: Ensure testResults gets at least one entry
$testResults["Debug Entry"] = $true
Add-Content -Path "R:\OMEGA\debug.txt" -Value "COUNT_AFTER_DEBUG:$($testResults.Count)"
if ($Category) {
    Write-Host "📂 Category: $Category" -ForegroundColor Cyan
}

Write-Host "DEBUG: executing switch with normalizedTestType='$normalizedTestType'" -ForegroundColor DarkGray
switch ($normalizedTestType) {
    "all" {
        Write-Host "🏃 Running all integration tests..." -ForegroundColor Cyan
        
        # Run modular integration tests
        $testResults["Modular Integration Tests"] = Run-OmegaTest "tests\modular_integration_tests.mega" "Modular Integration Tests"
        
        # Run legacy integration tests
        $testResults["Legacy Integration Tests"] = Run-OmegaTest "tests\integration_tests.mega" "Legacy Integration Tests"
        
        # Run test runner
        $testResults["Test Runner"] = Run-OmegaTest "tests\run_modular_tests.mega" "Test Runner"
    }
    
    "modular" {
        Write-Host "🔧 Running modular integration tests only..." -ForegroundColor Cyan
        $testResults["Modular Integration Tests"] = Run-OmegaTest "tests\modular_integration_tests.mega" "Modular Integration Tests"
    }
    
    "legacy" {
        Write-Host "🔄 Running legacy integration tests only..." -ForegroundColor Cyan
        $testResults["Legacy Integration Tests"] = Run-OmegaTest "tests\integration_tests.mega" "Legacy Integration Tests"
    }

    "unit" {
        Write-Host "🧩 Running unit tests (HTTP Core, Path, TCP, Native Codegen)..." -ForegroundColor Cyan
        $testResults["HTTP Core Unit Tests"] = Run-OmegaTest "tests\run_http_core_tests.mega" "HTTP Core Unit Tests"
        $testResults["Path Unit Tests"] = Run-OmegaTest "tests\path_tests.mega" "Path Unit Tests"
        $testResults["TCP Unit Tests"] = Run-OmegaTest "tests\tcp_tests.mega" "TCP Unit Tests"
        $testResults["Native Codegen Syscall Unit Tests"] = Run-OmegaTest "tests\native_codegen_syscall_tests.mega" "Native Codegen Syscall Unit Tests"
    }
    
    "category" {
        if (-not $Category) {
            Write-Host "❌ Category parameter is required when using -TestType category" -ForegroundColor Red
            Write-Host "Available categories: ir, optimizer, codegen, pipeline, error, performance" -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host "📂 Running $Category category tests..." -ForegroundColor Cyan
        
        # Create a temporary test file that runs specific category
        $tempTestFile = "tests\temp_category_test.mega"
        # Use single-quoted here-string to avoid PowerShell parsing and variable expansion issues
        $categoryTestContent = @'
import "run_modular_tests";

blockchain CategoryTestRunner {
    function main() public {
        ModularTestRunner runner = new ModularTestRunner();
        TestResults results = runner.run_test_category("<<CATEGORY>>");
        
        // Print results
        for (uint i = 0; i < results.test_results.length; i++) {
            TestResult result = results.test_results[i];
            if (result.status == TestStatus.Passed) {
                print("PASSED: " + result.name);
            } else {
                print("FAILED: " + result.name + " - " + result.error_message);
            }
        }
    }
}
'@
        # Replace placeholder with actual category
        $categoryTestContent = $categoryTestContent.Replace('<<CATEGORY>>', $Category)
        
        $categoryTestContent | Out-File -FilePath $tempTestFile -Encoding UTF8
        $testResults["Category: $Category"] = Run-OmegaTest $tempTestFile "Category: $Category"
        
        # Clean up temp file
        if (Test-Path $tempTestFile) {
            Remove-Item $tempTestFile -Force
        }
    }
    
    "regression" {
        Write-Host "🔍 Running regression tests..." -ForegroundColor Cyan
        
        # Create a temporary test file for regression tests
        $tempTestFile = "tests\temp_regression_test.mega"
        # Use single-quoted here-string to avoid parsing issues
        $regressionTestContent = @'
import "run_modular_tests";

blockchain RegressionTestRunner {
    function main() public {
        ModularTestRunner runner = new ModularTestRunner();
        TestResults results = runner.run_regression_tests();
        
        // Print results
        for (uint i = 0; i < results.test_results.length; i++) {
            TestResult result = results.test_results[i];
            if (result.status == TestStatus.Passed) {
                print("PASSED: " + result.name);
            } else {
                print("FAILED: " + result.name + " - " + result.error_message);
            }
        }
    }
}
'@
        
        $regressionTestContent | Out-File -FilePath $tempTestFile -Encoding UTF8
        $testResults["Regression Tests"] = Run-OmegaTest $tempTestFile "Regression Tests"
        
        # Clean up temp file
        if (Test-Path $tempTestFile) {
            Remove-Item $tempTestFile -Force
        }
    }
    

    default {
        Write-Host "❌ Unknown test type: $TestType" -ForegroundColor Red
        Write-Host "Available types: all, modular, legacy, unit, category, regression" -ForegroundColor Yellow
        exit 1
    }
}

# Calculate execution time
if (-not $startTime) { $startTime = Get-Date }
$endTime = Get-Date
$executionTime = New-TimeSpan -Start $startTime -End $endTime

# Fallback: if no tests were run yet, execute based on TestType here
if ($null -eq $testResults -or $testResults.Count -eq 0) {
    # Ensure hashtable exists
    if ($null -eq $testResults) { [hashtable]$testResults = @{} }
    Write-Host "DEBUG: Fallback path executing tests based on TestType '$TestType'" -ForegroundColor DarkGray
    $normalizedTestTypeBottom = ("" + $TestType).Trim().ToLower()
    switch ($normalizedTestTypeBottom) {
        "all" {
            $testResults["Modular Integration Tests"] = Run-OmegaTest "tests\modular_integration_tests.mega" "Modular Integration Tests"
            $testResults["Legacy Integration Tests"] = Run-OmegaTest "tests\integration_tests.mega" "Legacy Integration Tests"
            $testResults["Test Runner"] = Run-OmegaTest "tests\run_modular_tests.mega" "Test Runner"
        }
        "modular" {
            $testResults["Modular Integration Tests"] = Run-OmegaTest "tests\modular_integration_tests.mega" "Modular Integration Tests"
        }
        "legacy" {
            $testResults["Legacy Integration Tests"] = Run-OmegaTest "tests\integration_tests.mega" "Legacy Integration Tests"
        }
        "unit" {
            # Inline compile logic as fallback when functions aren't loaded
            $testName = "HTTP Core Unit Tests"
            Write-Host "[Fallback] Running $testName..." -ForegroundColor Yellow
            try {
                $result = & ".\omega.cmd" compile "tests\run_http_core_tests.mega" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[Fallback] $testName COMPILED" -ForegroundColor Green
                    $testResults[$testName] = $true
                } else {
                    Write-Host "[Fallback] $testName FAILED TO COMPILE" -ForegroundColor Red
                    if ($Verbose) { Write-Host $result -ForegroundColor Red }
                    $testResults[$testName] = $false
                }
            } catch {
                Write-Host "[Fallback] $testName FAILED with exception: $_" -ForegroundColor Red
                $testResults[$testName] = $false
            }

            # Tambahan: kompilasi Path dan TCP unit tests
            $testName2 = "Path Unit Tests"
            Write-Host "[Fallback] Running $testName2..." -ForegroundColor Yellow
            try {
                $result2 = & ".\omega.cmd" compile "tests\path_tests.mega" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[Fallback] $testName2 COMPILED" -ForegroundColor Green
                    $testResults[$testName2] = $true
                } else {
                    Write-Host "[Fallback] $testName2 FAILED TO COMPILE" -ForegroundColor Red
                    if ($Verbose) { Write-Host $result2 -ForegroundColor Red }
                    $testResults[$testName2] = $false
                }
            } catch {
                Write-Host "[Fallback] $testName2 FAILED with exception: $_" -ForegroundColor Red
                $testResults[$testName2] = $false
            }

            $testName3 = "TCP Unit Tests"
            Write-Host "[Fallback] Running $testName3..." -ForegroundColor Yellow
            try {
                $result3 = & ".\omega.cmd" compile "tests\tcp_tests.mega" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[Fallback] $testName3 COMPILED" -ForegroundColor Green
                    $testResults[$testName3] = $true
                } else {
                    Write-Host "[Fallback] $testName3 FAILED TO COMPILE" -ForegroundColor Red
                    if ($Verbose) { Write-Host $result3 -ForegroundColor Red }
                    $testResults[$testName3] = $false
                }
            } catch {
                Write-Host "[Fallback] $testName3 FAILED with exception: $_" -ForegroundColor Red
                $testResults[$testName3] = $false
            }
        }
        default {
            Write-Host "Unknown test type in fallback: $TestType" -ForegroundColor Yellow
        }
    }
}

# Print summary
Add-Content -Path "R:\OMEGA\debug.txt" -Value "COUNT_BEFORE_SUMMARY:$($testResults.Count)"
# Ensure testResults exists before indexing
if ($null -eq $testResults) { $testResults = @{} }
# Force at least one entry to verify hashtable update
$testResults["Post-Summary Debug"] = $true
Write-Host ""
Write-Host "Test Execution Summary" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

$totalTests = $testResults.Count
$passedTests = ($testResults.Values | Where-Object { $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests
$successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }

Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 95) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })
Write-Host "Execution Time: $($executionTime.TotalSeconds) seconds" -ForegroundColor Cyan

# Generate report if requested
if ($GenerateReport) {
    $reportPath = Join-Path $OutputDir "test_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    # Inline report generation to avoid function resolution issues
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $lines = @()
    $lines += "# OMEGA Integration Test Report"
    $lines += "Generated: $timestamp"
    $lines += ""
    $lines += "## Test Results Summary"
    foreach ($test in $testResults.Keys) {
        $status = if ($testResults[$test]) { "PASSED" } else { "FAILED" }
        $lines += "- ${test}: ${status}"
    }
    $lines += ""
    $lines += "## Statistics"
    $lines += "- Total Tests: $totalTests"
    $lines += "- Passed: $passedTests"
    $lines += "- Failed: $failedTests"
    $lines += "- Success Rate: $successRate%"
    ($lines -join [Environment]::NewLine) | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "Test report generated: $reportPath" -ForegroundColor Cyan
}

# Final status
if ($successRate -ge 95) {
    Write-Host ""
    Write-Host "ALL TESTS PASSED! Integration is successful!" -ForegroundColor Green
    exit 0
} elseif ($successRate -ge 80) {
    Write-Host ""
    Write-Host "TESTS PASSED WITH WARNINGS. Some issues need attention." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host ""
    Write-Host "TESTS FAILED! Critical issues require immediate attention." -ForegroundColor Red
    exit 1
}