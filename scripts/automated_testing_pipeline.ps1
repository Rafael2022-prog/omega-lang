# OMEGA Automated Testing Pipeline
# PowerShell script untuk menjalankan comprehensive testing dalam CI/CD pipeline
# Mendukung parallel execution, coverage reporting, dan performance benchmarking

param(
    [string]$TestSuite = "all",
    [string]$Target = "all",
    [switch]$Coverage = $false,
    [switch]$Benchmark = $false,
    [switch]$Parallel = $true,
    [string]$OutputFormat = "junit",
    [string]$ReportDir = "test-reports",
    [int]$Timeout = 3600,
    [switch]$Verbose = $false,
    [switch]$FailFast = $false,
    [string]$ConfigFile = "omega-test.toml"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors untuk output
$Colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "=" * 80 "Header"
    Write-ColorOutput " $Title" "Header"
    Write-ColorOutput "=" * 80 "Header"
    Write-Host ""
}

function Show-Help {
    Write-Host @"
OMEGA Automated Testing Pipeline

USAGE:
    .\automated_testing_pipeline.ps1 [OPTIONS]

OPTIONS:
    -TestSuite <suite>     Test suite to run (all, unit, integration, coverage, benchmark)
    -Target <target>       Compilation target (all, evm, solana, wasm, native)
    -Coverage              Enable code coverage analysis
    -Benchmark             Enable performance benchmarking
    -Parallel              Enable parallel test execution (default: true)
    -OutputFormat <format> Output format (junit, json, xml, console)
    -ReportDir <dir>       Directory for test reports (default: test-reports)
    -Timeout <seconds>     Test timeout in seconds (default: 3600)
    -Verbose               Enable verbose output
    -FailFast              Stop on first test failure
    -ConfigFile <file>     Test configuration file (default: omega-test.toml)

EXAMPLES:
    # Run all tests with coverage
    .\automated_testing_pipeline.ps1 -Coverage

    # Run unit tests for EVM target
    .\automated_testing_pipeline.ps1 -TestSuite unit -Target evm

    # Run benchmarks with verbose output
    .\automated_testing_pipeline.ps1 -Benchmark -Verbose

    # Run integration tests with fail-fast
    .\automated_testing_pipeline.ps1 -TestSuite integration -FailFast
"@
}

function Initialize-TestEnvironment {
    Write-Header "Initializing Test Environment"
    
    # Create report directory
    if (!(Test-Path $ReportDir)) {
        New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
        Write-ColorOutput "✓ Created report directory: $ReportDir" "Success"
    }
    
    # Verify OMEGA compiler
    try {
        $omegaVersion = & omega --version 2>$null
        Write-ColorOutput "✓ OMEGA Compiler: $omegaVersion" "Success"
    }
    catch {
        Write-ColorOutput "✗ OMEGA compiler not found or not working" "Error"
        exit 1
    }
    
    # Load test configuration
    if (Test-Path $ConfigFile) {
        Write-ColorOutput "✓ Loaded test configuration: $ConfigFile" "Success"
    } else {
        Write-ColorOutput "⚠ Test configuration not found, using defaults" "Warning"
    }
    
    # Set up environment variables
    $env:OMEGA_TEST_MODE = "automated"
    $env:OMEGA_TEST_PARALLEL = if ($Parallel) { "true" } else { "false" }
    $env:OMEGA_TEST_TIMEOUT = $Timeout
    $env:OMEGA_TEST_VERBOSE = if ($Verbose) { "true" } else { "false" }
    
    Write-ColorOutput "✓ Test environment initialized" "Success"
}

function Get-TestSuites {
    $suites = @()
    
    switch ($TestSuite.ToLower()) {
        "all" {
            $suites = @("unit", "integration", "coverage", "benchmark", "edge-cases")
        }
        "unit" {
            $suites = @("lexer", "parser", "semantic", "ir", "codegen", "optimizer")
        }
        "integration" {
            $suites = @("full-pipeline", "multi-target", "cross-chain")
        }
        "coverage" {
            $suites = @("comprehensive-coverage")
        }
        "benchmark" {
            $suites = @("performance", "memory", "compilation-speed")
        }
        default {
            $suites = @($TestSuite)
        }
    }
    
    return $suites
}

function Get-CompilationTargets {
    $targets = @()
    
    switch ($Target.ToLower()) {
        "all" {
            $targets = @("evm", "solana", "wasm", "native")
        }
        default {
            $targets = @($Target)
        }
    }
    
    return $targets
}

function Run-TestSuite {
    param(
        [string]$SuiteName,
        [string[]]$Targets
    )
    
    Write-Header "Running Test Suite: $SuiteName"
    
    $suiteResults = @{
        Name = $SuiteName
        Targets = @{}
        StartTime = Get-Date
        Success = $true
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        SkippedTests = 0
    }
    
    foreach ($target in $Targets) {
        Write-ColorOutput "Running tests for target: $target" "Info"
        
        $targetResult = Run-TargetTests -SuiteName $SuiteName -Target $target
        $suiteResults.Targets[$target] = $targetResult
        
        # Aggregate results
        $suiteResults.TotalTests += $targetResult.TotalTests
        $suiteResults.PassedTests += $targetResult.PassedTests
        $suiteResults.FailedTests += $targetResult.FailedTests
        $suiteResults.SkippedTests += $targetResult.SkippedTests
        
        if (!$targetResult.Success) {
            $suiteResults.Success = $false
            
            if ($FailFast) {
                Write-ColorOutput "✗ Failing fast due to test failure" "Error"
                break
            }
        }
    }
    
    $suiteResults.EndTime = Get-Date
    $suiteResults.Duration = $suiteResults.EndTime - $suiteResults.StartTime
    
    # Display suite summary
    Write-TestSuiteSummary -Results $suiteResults
    
    return $suiteResults
}

function Run-TargetTests {
    param(
        [string]$SuiteName,
        [string]$Target
    )
    
    $result = @{
        Suite = $SuiteName
        Target = $Target
        Success = $true
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        SkippedTests = 0
        StartTime = Get-Date
        TestResults = @()
    }
    
    try {
        # Build command based on suite and target
        $testCommand = Build-TestCommand -SuiteName $SuiteName -Target $Target
        
        if ($Verbose) {
            Write-ColorOutput "Executing: $testCommand" "Info"
        }
        
        # Execute tests
        $testOutput = Invoke-Expression $testCommand 2>&1
        
        # Parse test results
        $parsedResults = Parse-TestOutput -Output $testOutput -SuiteName $SuiteName
        
        $result.TotalTests = $parsedResults.TotalTests
        $result.PassedTests = $parsedResults.PassedTests
        $result.FailedTests = $parsedResults.FailedTests
        $result.SkippedTests = $parsedResults.SkippedTests
        $result.TestResults = $parsedResults.TestResults
        $result.Success = ($parsedResults.FailedTests -eq 0)
        
    }
    catch {
        Write-ColorOutput "✗ Error running tests for $SuiteName/$Target : $_" "Error"
        $result.Success = $false
        $result.FailedTests = 1
        $result.TotalTests = 1
    }
    
    $result.EndTime = Get-Date
    $result.Duration = $result.EndTime - $result.StartTime
    
    return $result
}

function Build-TestCommand {
    param(
        [string]$SuiteName,
        [string]$Target
    )
    
    $baseCommand = "omega test"
    $args = @()
    
    # Add suite-specific arguments
    switch ($SuiteName) {
        "lexer" { $args += "--suite lexer_tests" }
        "parser" { $args += "--suite parser_tests" }
        "semantic" { $args += "--suite semantic_tests" }
        "ir" { $args += "--suite ir_tests" }
        "codegen" { $args += "--suite codegen_tests" }
        "optimizer" { $args += "--suite optimizer_tests" }
        "integration" { $args += "--suite integration_tests" }
        "comprehensive-coverage" { $args += "--suite comprehensive_coverage_tests" }
        "performance" { $args += "--benchmark" }
        "memory" { $args += "--benchmark --memory" }
        "compilation-speed" { $args += "--benchmark --compilation" }
        default { $args += "--suite $SuiteName" }
    }
    
    # Add target-specific arguments
    if ($Target -ne "all") {
        $args += "--target $Target"
    }
    
    # Add coverage if requested
    if ($Coverage) {
        $args += "--coverage"
    }
    
    # Add parallel execution
    if ($Parallel) {
        $args += "--parallel"
    }
    
    # Add output format
    $args += "--output-format $OutputFormat"
    
    # Add report directory
    $args += "--report-dir $ReportDir"
    
    # Add timeout
    $args += "--timeout $Timeout"
    
    # Add verbose if requested
    if ($Verbose) {
        $args += "--verbose"
    }
    
    return "$baseCommand " + ($args -join " ")
}

function Parse-TestOutput {
    param(
        [string[]]$Output,
        [string]$SuiteName
    )
    
    $result = @{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        SkippedTests = 0
        TestResults = @()
    }
    
    foreach ($line in $Output) {
        # Parse test result lines
        if ($line -match "^TEST\s+(\w+)\s+(.+?)\s+\.\.\.\s+(PASS|FAIL|SKIP)") {
            $testName = $matches[2]
            $status = $matches[3]
            
            $testResult = @{
                Name = $testName
                Status = $status
                Suite = $SuiteName
            }
            
            $result.TestResults += $testResult
            $result.TotalTests++
            
            switch ($status) {
                "PASS" { $result.PassedTests++ }
                "FAIL" { $result.FailedTests++ }
                "SKIP" { $result.SkippedTests++ }
            }
        }
        
        # Parse summary lines
        if ($line -match "Tests:\s+(\d+)\s+passed,\s+(\d+)\s+failed,\s+(\d+)\s+skipped") {
            $result.PassedTests = [int]$matches[1]
            $result.FailedTests = [int]$matches[2]
            $result.SkippedTests = [int]$matches[3]
            $result.TotalTests = $result.PassedTests + $result.FailedTests + $result.SkippedTests
        }
    }
    
    return $result
}

function Write-TestSuiteSummary {
    param($Results)
    
    $status = if ($Results.Success) { "PASSED" } else { "FAILED" }
    $color = if ($Results.Success) { "Success" } else { "Error" }
    
    Write-Host ""
    Write-ColorOutput "Test Suite: $($Results.Name) - $status" $color
    Write-ColorOutput "Duration: $($Results.Duration.TotalSeconds.ToString('F2'))s" "Info"
    Write-ColorOutput "Total Tests: $($Results.TotalTests)" "Info"
    Write-ColorOutput "Passed: $($Results.PassedTests)" "Success"
    
    if ($Results.FailedTests -gt 0) {
        Write-ColorOutput "Failed: $($Results.FailedTests)" "Error"
    }
    
    if ($Results.SkippedTests -gt 0) {
        Write-ColorOutput "Skipped: $($Results.SkippedTests)" "Warning"
    }
    
    Write-Host ""
}

function Run-CoverageAnalysis {
    Write-Header "Running Coverage Analysis"
    
    try {
        $coverageCommand = "omega test --coverage --output-format json --report-dir $ReportDir"
        
        if ($Verbose) {
            Write-ColorOutput "Executing: $coverageCommand" "Info"
        }
        
        $coverageOutput = Invoke-Expression $coverageCommand 2>&1
        
        # Parse coverage results
        $coverageFile = Join-Path $ReportDir "coverage.json"
        if (Test-Path $coverageFile) {
            $coverageData = Get-Content $coverageFile | ConvertFrom-Json
            
            Write-ColorOutput "Coverage Results:" "Info"
            Write-ColorOutput "Overall Coverage: $($coverageData.overall_coverage)%" "Info"
            
            foreach ($component in $coverageData.components) {
                $color = if ($component.coverage -ge 80) { "Success" } elseif ($component.coverage -ge 60) { "Warning" } else { "Error" }
                Write-ColorOutput "  $($component.name): $($component.coverage)%" $color
            }
            
            # Generate coverage report
            Generate-CoverageReport -CoverageData $coverageData
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "✗ Coverage analysis failed: $_" "Error"
        return $false
    }
}

function Run-PerformanceBenchmarks {
    Write-Header "Running Performance Benchmarks"
    
    try {
        $benchmarkCommand = "omega test --benchmark --output-format json --report-dir $ReportDir"
        
        if ($Verbose) {
            Write-ColorOutput "Executing: $benchmarkCommand" "Info"
        }
        
        $benchmarkOutput = Invoke-Expression $benchmarkCommand 2>&1
        
        # Parse benchmark results
        $benchmarkFile = Join-Path $ReportDir "benchmarks.json"
        if (Test-Path $benchmarkFile) {
            $benchmarkData = Get-Content $benchmarkFile | ConvertFrom-Json
            
            Write-ColorOutput "Benchmark Results:" "Info"
            
            foreach ($benchmark in $benchmarkData.benchmarks) {
                Write-ColorOutput "  $($benchmark.name):" "Info"
                Write-ColorOutput "    Time: $($benchmark.time)ms" "Info"
                Write-ColorOutput "    Memory: $($benchmark.memory)MB" "Info"
                
                if ($benchmark.regression) {
                    Write-ColorOutput "    ⚠ Performance regression detected!" "Warning"
                }
            }
            
            # Generate benchmark report
            Generate-BenchmarkReport -BenchmarkData $benchmarkData
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "✗ Performance benchmarking failed: $_" "Error"
        return $false
    }
}

function Generate-CoverageReport {
    param($CoverageData)
    
    $reportFile = Join-Path $ReportDir "coverage-report.html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>OMEGA Coverage Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .coverage-high { color: green; font-weight: bold; }
        .coverage-medium { color: orange; font-weight: bold; }
        .coverage-low { color: red; font-weight: bold; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>OMEGA Test Coverage Report</h1>
        <p>Generated: $(Get-Date)</p>
        <p>Overall Coverage: <span class="coverage-high">$($CoverageData.overall_coverage)%</span></p>
    </div>
    
    <h2>Component Coverage</h2>
    <table>
        <tr><th>Component</th><th>Coverage</th><th>Lines Covered</th><th>Total Lines</th></tr>
"@

    foreach ($component in $CoverageData.components) {
        $cssClass = if ($component.coverage -ge 80) { "coverage-high" } elseif ($component.coverage -ge 60) { "coverage-medium" } else { "coverage-low" }
        
        $html += @"
        <tr>
            <td>$($component.name)</td>
            <td class="$cssClass">$($component.coverage)%</td>
            <td>$($component.lines_covered)</td>
            <td>$($component.total_lines)</td>
        </tr>
"@
    }

    $html += @"
    </table>
</body>
</html>
"@

    $html | Out-File -FilePath $reportFile -Encoding UTF8
    Write-ColorOutput "✓ Coverage report generated: $reportFile" "Success"
}

function Generate-BenchmarkReport {
    param($BenchmarkData)
    
    $reportFile = Join-Path $ReportDir "benchmark-report.html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>OMEGA Benchmark Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .regression { color: red; font-weight: bold; }
        .improvement { color: green; font-weight: bold; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>OMEGA Performance Benchmark Report</h1>
        <p>Generated: $(Get-Date)</p>
    </div>
    
    <h2>Benchmark Results</h2>
    <table>
        <tr><th>Benchmark</th><th>Time (ms)</th><th>Memory (MB)</th><th>Status</th></tr>
"@

    foreach ($benchmark in $BenchmarkData.benchmarks) {
        $statusClass = if ($benchmark.regression) { "regression" } else { "improvement" }
        $status = if ($benchmark.regression) { "Regression" } else { "OK" }
        
        $html += @"
        <tr>
            <td>$($benchmark.name)</td>
            <td>$($benchmark.time)</td>
            <td>$($benchmark.memory)</td>
            <td class="$statusClass">$status</td>
        </tr>
"@
    }

    $html += @"
    </table>
</body>
</html>
"@

    $html | Out-File -FilePath $reportFile -Encoding UTF8
    Write-ColorOutput "✓ Benchmark report generated: $reportFile" "Success"
}

function Generate-FinalReport {
    param($AllResults)
    
    Write-Header "Generating Final Test Report"
    
    $totalTests = ($AllResults | ForEach-Object { $_.TotalTests } | Measure-Object -Sum).Sum
    $totalPassed = ($AllResults | ForEach-Object { $_.PassedTests } | Measure-Object -Sum).Sum
    $totalFailed = ($AllResults | ForEach-Object { $_.FailedTests } | Measure-Object -Sum).Sum
    $totalSkipped = ($AllResults | ForEach-Object { $_.SkippedTests } | Measure-Object -Sum).Sum
    
    $overallSuccess = ($totalFailed -eq 0)
    $successRate = if ($totalTests -gt 0) { [math]::Round(($totalPassed / $totalTests) * 100, 2) } else { 0 }
    
    # Console summary
    Write-Host ""
    Write-ColorOutput "=" * 80 "Header"
    Write-ColorOutput " FINAL TEST RESULTS" "Header"
    Write-ColorOutput "=" * 80 "Header"
    Write-Host ""
    
    $statusColor = if ($overallSuccess) { "Success" } else { "Error" }
    $status = if ($overallSuccess) { "PASSED" } else { "FAILED" }
    
    Write-ColorOutput "Overall Status: $status" $statusColor
    Write-ColorOutput "Success Rate: $successRate%" "Info"
    Write-ColorOutput "Total Tests: $totalTests" "Info"
    Write-ColorOutput "Passed: $totalPassed" "Success"
    
    if ($totalFailed -gt 0) {
        Write-ColorOutput "Failed: $totalFailed" "Error"
    }
    
    if ($totalSkipped -gt 0) {
        Write-ColorOutput "Skipped: $totalSkipped" "Warning"
    }
    
    Write-Host ""
    
    # Generate JUnit XML report
    Generate-JUnitReport -Results $AllResults -TotalTests $totalTests -TotalPassed $totalPassed -TotalFailed $totalFailed -TotalSkipped $totalSkipped
    
    return $overallSuccess
}

function Generate-JUnitReport {
    param($Results, $TotalTests, $TotalPassed, $TotalFailed, $TotalSkipped)
    
    $reportFile = Join-Path $ReportDir "junit-report.xml"
    
    $xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<testsuites tests="$TotalTests" failures="$TotalFailed" skipped="$TotalSkipped" time="0">
"@

    foreach ($suiteResult in $Results) {
        $xml += @"
    <testsuite name="$($suiteResult.Name)" tests="$($suiteResult.TotalTests)" failures="$($suiteResult.FailedTests)" skipped="$($suiteResult.SkippedTests)" time="$($suiteResult.Duration.TotalSeconds)">
"@

        foreach ($target in $suiteResult.Targets.Keys) {
            $targetResult = $suiteResult.Targets[$target]
            
            foreach ($testResult in $targetResult.TestResults) {
                $xml += @"
        <testcase name="$($testResult.Name)" classname="$($testResult.Suite).$target" time="0">
"@

                if ($testResult.Status -eq "FAIL") {
                    $xml += @"
            <failure message="Test failed" type="TestFailure">Test $($testResult.Name) failed</failure>
"@
                } elseif ($testResult.Status -eq "SKIP") {
                    $xml += @"
            <skipped message="Test skipped" />
"@
                }

                $xml += @"
        </testcase>
"@
            }
        }

        $xml += @"
    </testsuite>
"@
    }

    $xml += @"
</testsuites>
"@

    $xml | Out-File -FilePath $reportFile -Encoding UTF8
    Write-ColorOutput "✓ JUnit report generated: $reportFile" "Success"
}

# Main execution
function Main {
    if ($args -contains "-Help" -or $args -contains "--help" -or $args -contains "-h") {
        Show-Help
        return
    }
    
    Write-Header "OMEGA Automated Testing Pipeline"
    Write-ColorOutput "Starting automated testing with configuration:" "Info"
    Write-ColorOutput "  Test Suite: $TestSuite" "Info"
    Write-ColorOutput "  Target: $Target" "Info"
    Write-ColorOutput "  Coverage: $Coverage" "Info"
    Write-ColorOutput "  Benchmark: $Benchmark" "Info"
    Write-ColorOutput "  Parallel: $Parallel" "Info"
    Write-ColorOutput "  Output Format: $OutputFormat" "Info"
    Write-ColorOutput "  Report Directory: $ReportDir" "Info"
    
    # Initialize test environment
    Initialize-TestEnvironment
    
    # Get test suites and targets
    $testSuites = Get-TestSuites
    $compilationTargets = Get-CompilationTargets
    
    Write-ColorOutput "Test suites to run: $($testSuites -join ', ')" "Info"
    Write-ColorOutput "Compilation targets: $($compilationTargets -join ', ')" "Info"
    
    # Run all test suites
    $allResults = @()
    
    foreach ($suite in $testSuites) {
        $suiteResult = Run-TestSuite -SuiteName $suite -Targets $compilationTargets
        $allResults += $suiteResult
        
        if (!$suiteResult.Success -and $FailFast) {
            Write-ColorOutput "✗ Stopping execution due to test failure (fail-fast enabled)" "Error"
            break
        }
    }
    
    # Run coverage analysis if requested
    if ($Coverage) {
        $coverageSuccess = Run-CoverageAnalysis
        if (!$coverageSuccess -and $FailFast) {
            Write-ColorOutput "✗ Stopping execution due to coverage analysis failure" "Error"
            exit 1
        }
    }
    
    # Run performance benchmarks if requested
    if ($Benchmark) {
        $benchmarkSuccess = Run-PerformanceBenchmarks
        if (!$benchmarkSuccess -and $FailFast) {
            Write-ColorOutput "✗ Stopping execution due to benchmark failure" "Error"
            exit 1
        }
    }
    
    # Generate final report
    $overallSuccess = Generate-FinalReport -AllResults $allResults
    
    # Exit with appropriate code
    if ($overallSuccess) {
        Write-ColorOutput "✓ All tests completed successfully!" "Success"
        exit 0
    } else {
        Write-ColorOutput "✗ Some tests failed!" "Error"
        exit 1
    }
}

# Run main function
Main