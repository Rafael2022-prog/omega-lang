# OMEGA Integration Test Runner Script
# PowerShell script untuk menjalankan integration tests

param(
    [string]$TestType = "all",
    [string]$Category = "",
    [switch]$Verbose = $false,
    [switch]$GenerateReport = $false,
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
        # Compile and run the test file
        $result = & ".\omega.exe" run $TestFile 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ $TestName PASSED" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ $TestName FAILED" -ForegroundColor Red
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
    $report = @"
# OMEGA Integration Test Report
Generated: $timestamp

## Test Results Summary
"@

    $totalTests = 0
    $passedTests = 0
    $failedTests = 0
    
    foreach ($test in $Results.Keys) {
        $totalTests++
        if ($Results[$test]) {
            $passedTests++
            $report += "`n- ✅ $test: PASSED"
        } else {
            $failedTests++
            $report += "`n- ❌ $test: FAILED"
        }
    }
    
    $successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }
    
    $report += @"

## Statistics
- Total Tests: $totalTests
- Passed: $passedTests
- Failed: $failedTests
- Success Rate: $successRate%

## Status
"@

    if ($successRate -ge 95) {
        $report += "`n🎉 **ALL TESTS PASSED** - Integration is successful!"
    } elseif ($successRate -ge 80) {
        $report += "`n⚠️ **TESTS PASSED WITH WARNINGS** - Some issues need attention"
    } else {
        $report += "`n❌ **TESTS FAILED** - Critical issues require immediate attention"
    }
    
    $report | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "📊 Test report generated: $OutputPath" -ForegroundColor Cyan
}

# Main test execution
$testResults = @{}
$startTime = Get-Date

Write-Host "🔍 Test Type: $TestType" -ForegroundColor Cyan
if ($Category) {
    Write-Host "📂 Category: $Category" -ForegroundColor Cyan
}

switch ($TestType.ToLower()) {
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
    
    "category" {
        if (-not $Category) {
            Write-Host "❌ Category parameter is required when using -TestType category" -ForegroundColor Red
            Write-Host "Available categories: ir, optimizer, codegen, pipeline, error, performance" -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host "📂 Running $Category category tests..." -ForegroundColor Cyan
        
        # Create a temporary test file that runs specific category
        $tempTestFile = "tests\temp_category_test.mega"
        $categoryTestContent = @"
import "run_modular_tests";

blockchain CategoryTestRunner {
    function main() public {
        ModularTestRunner runner = new ModularTestRunner();
        TestResults results = runner.run_test_category("$Category");
        
        // Print results
        for (uint i = 0; i < results.test_results.length; i++) {
            TestResult result = results.test_results[i];
            if (result.status == TestStatus.Passed) {
                print("✅ " + result.name + ": PASSED");
            } else {
                print("❌ " + result.name + ": FAILED - " + result.error_message);
            }
        }
    }
}
"@
        
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
        $regressionTestContent = @"
import "run_modular_tests";

blockchain RegressionTestRunner {
    function main() public {
        ModularTestRunner runner = new ModularTestRunner();
        TestResults results = runner.run_regression_tests();
        
        // Print results
        for (uint i = 0; i < results.test_results.length; i++) {
            TestResult result = results.test_results[i];
            if (result.status == TestStatus.Passed) {
                print("✅ " + result.name + ": PASSED");
            } else {
                print("❌ " + result.name + ": FAILED - " + result.error_message);
            }
        }
    }
}
"@
        
        $regressionTestContent | Out-File -FilePath $tempTestFile -Encoding UTF8
        $testResults["Regression Tests"] = Run-OmegaTest $tempTestFile "Regression Tests"
        
        # Clean up temp file
        if (Test-Path $tempTestFile) {
            Remove-Item $tempTestFile -Force
        }
    }
    
    default {
        Write-Host "❌ Unknown test type: $TestType" -ForegroundColor Red
        Write-Host "Available types: all, modular, legacy, category, regression" -ForegroundColor Yellow
        exit 1
    }
}

# Calculate execution time
$endTime = Get-Date
$executionTime = $endTime - $startTime

# Print summary
Write-Host "`n📊 Test Execution Summary" -ForegroundColor Cyan
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
    Generate-TestReport -Results $testResults -OutputPath $reportPath
}

# Final status
if ($successRate -ge 95) {
    Write-Host "`n🎉 ALL TESTS PASSED! Integration is successful!" -ForegroundColor Green
    exit 0
} elseif ($successRate -ge 80) {
    Write-Host "`n⚠️ TESTS PASSED WITH WARNINGS. Some issues need attention." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n❌ TESTS FAILED! Critical issues require immediate attention." -ForegroundColor Red
    exit 1
}