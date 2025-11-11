# OMEGA Memory Management Test Execution Script
# PowerShell script for running memory management tests

param(
    [switch]$Verbose,
    [string]$TestFilter = "",
    [switch]$Help,
    [switch]$Parallel,
    [int]$MaxParallel = 4,
    [switch]$Report,
    [string]$ReportPath = "test_reports/memory"
)

# Display help if requested
if ($Help) {
    Write-Host "OMEGA Memory Management Test Runner"
    Write-Host "Usage: .\run_memory_tests.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Verbose           Enable verbose logging"
    Write-Host "  -TestFilter <name> Run specific test"
    Write-Host "  -Parallel          Run tests in parallel"
    Write-Host "  -MaxParallel <n>   Maximum parallel tests (default: 4)"
    Write-Host "  -Report            Generate detailed report"
    Write-Host "  -ReportPath <path> Report output directory"
    Write-Host "  -Help              Show this help"
    Write-Host ""
    Write-Host "Available tests:"
    Write-Host "  basic_allocation"
    Write-Host "  multiple_allocations"
    Write-Host "  deallocation"
    Write-Host "  garbage_collection"
    Write-Host "  memory_pool"
    Write-Host "  memory_fragmentation"
    Write-Host "  concurrent_allocations"
    Write-Host "  memory_statistics"
    Write-Host "  error_handling"
    Write-Host "  performance"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\run_memory_tests.ps1 -Verbose"
    Write-Host "  .\run_memory_tests.ps1 -TestFilter basic_allocation"
    Write-Host "  .\run_memory_tests.ps1 -Parallel -MaxParallel 8"
    exit 0
}

# Initialize variables
$ErrorActionPreference = "Stop"
$script:StartTime = Get-Date
$script:TestResults = @()
$script:PeakMemory = 0
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

# Configuration
$OmegaExe = ".\omega.exe"
$TestFile = "run_memory_tests.mega"
$MemoryTestFile = "tests\memory\test_memory_manager.mega"

# Colors for output
$Colors = @{
    Success = "Green"
    Error = "Red"
    Warning = "Yellow"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-TestHeader {
    param([string]$Message)
    Write-Host "`n$('=' * 60)" -ForegroundColor $Colors.Header
    Write-Host $Message -ForegroundColor $Colors.Header
    Write-Host "$('=' * 60)" -ForegroundColor $Colors.Header
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    $status = if ($Passed) { "✅ PASSED" } else { "❌ FAILED" }
    $color = if ($Passed) { $Colors.Success } else { $Colors.Error }
    
    Write-Host "  $TestName`: $status" -ForegroundColor $color
    if ($Details) {
        Write-Host "    $Details" -ForegroundColor $Colors.Info
    }
}

function Get-MemoryUsage {
    # Get current memory usage in bytes
    $process = Get-Process -Id $PID
    return $process.WorkingSet64
}

function Test-OmegaInstallation {
    if (-not (Test-Path $OmegaExe)) {
        Write-Host "Error: OMEGA executable not found at $OmegaExe" -ForegroundColor $Colors.Error
        Write-Host "Please build OMEGA first using build.ps1" -ForegroundColor $Colors.Warning
        return $false
    }
    
    if (-not (Test-Path $TestFile)) {
        Write-Host "Error: Test file not found at $TestFile" -ForegroundColor $Colors.Error
        return $false
    }
    
    if (-not (Test-Path $MemoryTestFile)) {
        Write-Host "Error: Memory test file not found at $MemoryTestFile" -ForegroundColor $Colors.Error
        return $false
    }
    
    return $true
}

function Invoke-MemoryTest {
    param(
        [string]$TestFilter = "",
        [bool]$Verbose = $false
    )
    
    Write-TestHeader "Running OMEGA Memory Management Tests"
    
    # Build command arguments
    $arguments = @($TestFile)
    
    if ($Verbose) {
        $arguments += "--verbose"
    }
    
    if ($TestFilter) {
        $arguments += "--test"
        $arguments += $TestFilter
    }
    
    if ($Verbose) {
        Write-Host "Command: $OmegaExe $($arguments -join ' ')" -ForegroundColor $Colors.Info
    }
    
    # Execute test
    try {
        $initialMemory = Get-MemoryUsage
        
        $output = & $OmegaExe $arguments 2>&1
        $exitCode = $LASTEXITCODE
        
        $finalMemory = Get-MemoryUsage
        $memoryUsed = $finalMemory - $initialMemory
        
        if ($script:PeakMemory -lt $finalMemory) {
            $script:PeakMemory = $finalMemory
        }
        
        # Parse results from output
        $results = Parse-TestOutput -Output $output
        
        return @{
            Success = ($exitCode -eq 0)
            Output = $output
            ExitCode = $exitCode
            MemoryUsed = $memoryUsed
            Results = $results
        }
    }
    catch {
        Write-Host "Error executing test: $_" -ForegroundColor $Colors.Error
        return @{
            Success = $false
            Output = $_.Exception.Message
            ExitCode = 1
            MemoryUsed = 0
            Results = @{}
        }
    }
}

function Parse-TestOutput {
    param([string[]]$Output)
    
    $results = @{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        PeakMemory = 0
        SuccessRate = 0
    }
    
    foreach ($line in $Output) {
        if ($line -match "Total Tests:\s+(\d+)") {
            $results.TotalTests = [int]$Matches[1]
        }
        elseif ($line -match "Passed:\s+(\d+)") {
            $results.PassedTests = [int]$Matches[1]
        }
        elseif ($line -match "Failed:\s+(\d+)") {
            $results.FailedTests = [int]$Matches[1]
        }
        elseif ($line -match "Peak Memory:\s+(\d+)") {
            $results.PeakMemory = [int64]$Matches[1]
        }
        elseif ($line -match "Success Rate:\s+(\d+)%") {
            $results.SuccessRate = [int]$Matches[1]
        }
    }
    
    return $results
}

function Generate-TestReport {
    param(
        [hashtable]$Results,
        [timespan]$Duration,
        [string]$ReportPath
    )
    
    if (-not $Report) {
        return
    }
    
    # Create report directory
    if (-not (Test-Path $ReportPath)) {
        New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = Join-Path $ReportPath "memory_test_report_$timestamp.html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>OMEGA Memory Management Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .summary { display: flex; gap: 20px; margin: 20px 0; }
        .metric { background-color: #e8f4f8; padding: 15px; border-radius: 5px; text-align: center; }
        .metric h3 { margin: 0; color: #2c5aa0; }
        .metric .value { font-size: 24px; font-weight: bold; }
        .results { margin: 20px 0; }
        .test-result { padding: 10px; margin: 5px 0; border-radius: 3px; }
        .passed { background-color: #d4edda; border: 1px solid #c3e6cb; }
        .failed { background-color: #f8d7da; border: 1px solid #f5c6cb; }
        .details { font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="header">
        <h1>OMEGA Memory Management Test Report</h1>
        <p>Generated: $(Get-Date)</p>
        <p>Duration: $($Duration.ToString('hh\:mm\:ss'))</p>
    </div>
    
    <div class="summary">
        <div class="metric">
            <h3>Total Tests</h3>
            <div class="value">$($Results.TotalTests)</div>
        </div>
        <div class="metric">
            <h3>Passed</h3>
            <div class="value" style="color: green;">$($Results.PassedTests)</div>
        </div>
        <div class="metric">
            <h3>Failed</h3>
            <div class="value" style="color: red;">$($Results.FailedTests)</div>
        </div>
        <div class="metric">
            <h3>Success Rate</h3>
            <div class="value">$($Results.SuccessRate)%</div>
        </div>
        <div class="metric">
            <h3>Peak Memory</h3>
            <div class="value">$([math]::Round($Results.PeakMemory / 1MB, 2)) MB</div>
        </div>
    </div>
    
    <div class="results">
        <h2>Test Results</h2>
        <!-- Detailed results would go here -->
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Host "Report generated: $reportFile" -ForegroundColor $Colors.Success
}

# Main execution
function Main {
    try {
        # Validate installation
        if (-not (Test-OmegaInstallation)) {
            exit 1
        }
        
        Write-TestHeader "OMEGA Memory Management Test Suite"
        
        if ($Parallel) {
            Write-Host "Parallel execution enabled (Max: $MaxParallel)" -ForegroundColor $Colors.Info
        }
        
        if ($TestFilter) {
            Write-Host "Running specific test: $TestFilter" -ForegroundColor $Colors.Info
        }
        
        # Run tests
        $testResults = Invoke-MemoryTest -TestFilter $TestFilter -Verbose $Verbose
        
        # Calculate duration
        $duration = (Get-Date) - $script:StartTime
        
        # Display results
        Write-Host "`n=== Test Results ===" -ForegroundColor $Colors.Header
        Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor $Colors.Info
        Write-Host "Memory Used: $([math]::Round($testResults.MemoryUsed / 1MB, 2)) MB" -ForegroundColor $Colors.Info
        
        if ($testResults.Results.Count -gt 0) {
            Write-Host "Total Tests: $($testResults.Results.TotalTests)" -ForegroundColor $Colors.Info
            Write-Host "Passed: $($testResults.Results.PassedTests)" -ForegroundColor $Colors.Success
            Write-Host "Failed: $($testResults.Results.FailedTests)" -ForegroundColor $Colors.Error
            Write-Host "Success Rate: $($testResults.Results.SuccessRate)%" -ForegroundColor $Colors.Info
        }
        
        # Generate report if requested
        if ($Report) {
            Generate-TestReport -Results $testResults.Results -Duration $duration -ReportPath $ReportPath
        }
        
        # Final status
        if ($testResults.Success) {
            Write-Host "`n✅ All memory tests completed successfully!" -ForegroundColor $Colors.Success
            exit 0
        } else {
            Write-Host "`n❌ Some memory tests failed!" -ForegroundColor $Colors.Error
            exit 1
        }
        
    } catch {
        Write-Host "Error: $_" -ForegroundColor $Colors.Error
        exit 1
    }
}

# Execute main function
Main