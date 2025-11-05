# Simple OMEGA Performance Benchmark
param(
    [string]$OutputDir = "benchmark_reports"
)

$OmegaRoot = Split-Path -Parent $PSScriptRoot
$BenchmarkResultsDir = Join-Path $OmegaRoot $OutputDir
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create results directory
if (-not (Test-Path $BenchmarkResultsDir)) {
    New-Item -ItemType Directory -Path $BenchmarkResultsDir -Force | Out-Null
}

Write-Host "⚡ OMEGA Simple Performance Benchmark" -ForegroundColor Blue
Write-Host "====================================" -ForegroundColor Blue
Write-Host "Timestamp: $(Get-Date)"
Write-Host ""

# Function to measure execution time
function Measure-ExecutionTime {
    param([scriptblock]$ScriptBlock)
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $ScriptBlock
        $success = $true
    } catch {
        $success = $false
        Write-Host "Error: $_" -ForegroundColor Red
    }
    $stopwatch.Stop()
    return @{
        Time = $stopwatch.Elapsed.TotalSeconds
        Success = $success
    }
}

# Ensure OMEGA built using native .mega build script
$OmegaBinary = Join-Path $OmegaRoot "omega"
if (-not (Test-Path $OmegaBinary)) {
    Write-Host "🔨 Building OMEGA (native) ..." -ForegroundColor Yellow
    $buildResult = Measure-ExecutionTime {
        & "$OmegaRoot\build_omega_native.ps1" 2>&1 | Out-Null
    }
    Write-Host "Build time: $($buildResult.Time) seconds" -ForegroundColor Green
    
    if (-not $buildResult.Success -or -not (Test-Path $OmegaBinary)) {
        Write-Host "❌ Failed to build OMEGA" -ForegroundColor Red
        exit 1
    }
}

# Create test directory
$TestDir = Join-Path $OmegaRoot "benchmark_tests"
if (-not (Test-Path $TestDir)) {
    New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
}

# Create simple test file
$SimpleTestFile = Join-Path $TestDir "simple.omega"
$SimpleContent = 'blockchain Simple { state { uint256 value; } function getValue() public view returns (uint256) { return value; } }'
Set-Content -Path $SimpleTestFile -Value $SimpleContent

Write-Host "🧪 Running compilation tests..." -ForegroundColor Yellow

# Test simple compilation
if (Test-Path $OmegaBinary) {
    Write-Host "Testing simple compilation..." -ForegroundColor Cyan
    $compileResult = Measure-ExecutionTime {
        $null = & $OmegaBinary compile $SimpleTestFile --target evm
    }
    
    if ($compileResult.Success) {
        Write-Host "✅ Simple compilation: $($compileResult.Time) seconds" -ForegroundColor Green
    } else {
        Write-Host "❌ Simple compilation failed" -ForegroundColor Red
    }
    
    # Test binary size
    if (Test-Path $OmegaBinary) {
        $binarySize = (Get-Item $OmegaBinary).Length / 1MB
        Write-Host "📦 Binary size: $([math]::Round($binarySize, 2)) MB" -ForegroundColor Green
    }
    
    # Test memory usage (if process is running)
    $omegaProcess = Get-Process -Name "omega" -ErrorAction SilentlyContinue
    if ($omegaProcess) {
        $memoryMB = [math]::Round($omegaProcess.WorkingSet64 / 1MB, 2)
        Write-Host "💾 Memory usage: $memoryMB MB" -ForegroundColor Green
    }
} else {
    Write-Host "❌ OMEGA binary not found" -ForegroundColor Red
    exit 1
}

# Performance assessment
Write-Host ""
Write-Host "📊 Performance Assessment" -ForegroundColor Blue
Write-Host "========================" -ForegroundColor Blue

$issues = 0

if ($compileResult.Success) {
    if ($compileResult.Time -gt 5.0) {
        Write-Host "⚠️  Compilation time is high: $($compileResult.Time)s" -ForegroundColor Yellow
        $issues++
    } else {
        Write-Host "✅ Compilation time is acceptable: $($compileResult.Time)s" -ForegroundColor Green
    }
} else {
    Write-Host "❌ Compilation failed" -ForegroundColor Red
    $issues++
}

if ($binarySize -gt 100) {
    Write-Host "⚠️  Binary size is large: $([math]::Round($binarySize, 2))MB" -ForegroundColor Yellow
    $issues++
} else {
    Write-Host "✅ Binary size is acceptable: $([math]::Round($binarySize, 2))MB" -ForegroundColor Green
}

Write-Host ""
if ($issues -eq 0) {
    Write-Host "🎉 All performance benchmarks passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Performance benchmarks completed with $issues concerns" -ForegroundColor Yellow
    exit 1
}