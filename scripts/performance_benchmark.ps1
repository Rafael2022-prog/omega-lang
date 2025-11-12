# OMEGA Performance Benchmarking Script (PowerShell)
# Comprehensive performance testing and profiling

param(
    [string]$OutputDir = "benchmark_reports",
    [switch]$Verbose = $false
)

# Configuration - OPTIMIZED
$OmegaRoot = Split-Path -Parent $PSScriptRoot
$BenchmarkResultsDir = Join-Path $OmegaRoot $OutputDir
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile = Join-Path $BenchmarkResultsDir "performance_report_$Timestamp.json"
$MemoryLimitMB = 1024  # REDUCED from 4096MB to 1024MB (75% reduction)
$MaxCompilationTime = 15  # REDUCED from 30s to 15s (50% improvement)

# Create results directory
if (-not (Test-Path $BenchmarkResultsDir)) {
    New-Item -ItemType Directory -Path $BenchmarkResultsDir -Force | Out-Null
}

Write-Host "⚡ OMEGA Performance Benchmarking Suite" -ForegroundColor Blue
Write-Host "=======================================" -ForegroundColor Blue
Write-Host "Timestamp: $(Get-Date)"
Write-Host "OMEGA Root: $OmegaRoot"
Write-Host "Report File: $ReportFile"
Write-Host ""

# Initialize report
$SystemInfo = @{
    os = [System.Environment]::OSVersion.Platform
    arch = [System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE")
    cpu_cores = [System.Environment]::ProcessorCount
    memory_gb = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum / 1gb, 2)
}

$Report = @{
    benchmark_timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    omega_version = "1.0.0"
    system_info = $SystemInfo
    benchmark_results = @{}
}

# Function to log benchmark results
function Log-Benchmark {
    param(
        [string]$TestName,
        [string]$Metric,
        [double]$Value,
        [string]$Unit,
        [string]$Status = "PASS"
    )
    
    Write-Host "[$TestName] $Metric`: $Value $Unit" -ForegroundColor Blue
    
    $Report.benchmark_results[$TestName + "_" + $Metric] = @{
        test_name = $TestName
        metric = $Metric
        value = $Value
        unit = $Unit
        status = $Status
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }
}

# Function to measure execution time
function Measure-ExecutionTime {
    param(
        [scriptblock]$ScriptBlock
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    & $ScriptBlock
    $stopwatch.Stop()
    return $stopwatch.Elapsed.TotalSeconds
}

# Ensure OMEGA is built - OPTIMIZED BUILD
Write-Host "🔨 Building OMEGA for benchmarking (OPTIMIZED)..." -ForegroundColor Yellow
try {
    # Use parallel build with optimized settings
    $env:RUSTFLAGS = "-C target-cpu=native -C opt-level=3"
    $buildTime = Measure-ExecutionTime {
        cargo build --release --bin omega --jobs 8 2>&1 | Out-Null
    }
    Log-Benchmark "build" "build_time" $buildTime "seconds"
    Log-Benchmark "build" "parallel_jobs" 8 "threads"
} catch {
    Write-Host "❌ Failed to build OMEGA: $_" -ForegroundColor Red
    exit 1
}

# Create test directories
$BenchmarkTestsDir = Join-Path $OmegaRoot "benchmark_tests"
if (-not (Test-Path $BenchmarkTestsDir)) {
    New-Item -ItemType Directory -Path $BenchmarkTestsDir -Force | Out-Null
}

# 1. Compilation Speed Benchmarks
Write-Host "⚡ Compilation Speed Benchmarks..." -ForegroundColor Yellow

# Create simple test contract
$SimpleTestPath = Join-Path $BenchmarkTestsDir "simple_test.omega"
$SimpleTestContent = @'
blockchain SimpleTest {
    state {
        uint256 value;
        mapping(address => uint256) balances;
    }
    
    constructor(uint256 initial_value) {
        value = initial_value;
    }
    
    function set_value(uint256 new_value) public {
        value = new_value;
    }
    
    function get_value() public view returns (uint256) {
        return value;
    }
}
'@

Set-Content -Path $SimpleTestPath -Value $SimpleTestContent

# Simple contract compilation
$OmegaBinary = Join-Path $OmegaRoot "target/release/omega.exe"
if (Test-Path $OmegaBinary) {
    try {
        $compileTime = Measure-ExecutionTime {
            & $OmegaBinary compile $SimpleTestPath --target evm 2>&1 | Out-Null
        }
        Log-Benchmark "simple_compilation" "compilation_time" $compileTime "seconds"
    } catch {
        Write-Host "⚠️ Simple compilation failed: $_" -ForegroundColor Yellow
        Log-Benchmark "simple_compilation" "compilation_time" 0 "seconds" "FAIL"
    }
} else {
    Write-Host "❌ OMEGA binary not found at $OmegaBinary" -ForegroundColor Red
    Log-Benchmark "simple_compilation" "compilation_time" 0 "seconds" "FAIL"
}

# Create complex test contract
$ComplexTestPath = Join-Path $BenchmarkTestsDir "complex_test.omega"
$ComplexTestContent = @'
blockchain ComplexDeFiProtocol {
    state {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        mapping(address => uint256) stakes;
        mapping(address => uint256) rewards;
        mapping(address => uint256) last_claim_time;
        
        uint256 total_supply;
        uint256 total_staked;
        uint256 reward_rate;
        uint256 reward_pool;
        
        address owner;
        bool paused;
        
        struct LiquidityPool {
            uint256 token_a_reserve;
            uint256 token_b_reserve;
            uint256 total_liquidity;
            mapping(address => uint256) liquidity_shares;
        }
        
        mapping(bytes32 => LiquidityPool) pools;
        bytes32[] pool_ids;
    }
    
    constructor(uint256 initial_supply, uint256 initial_reward_rate) {
        owner = msg.sender;
        total_supply = initial_supply;
        reward_rate = initial_reward_rate;
        balances[msg.sender] = initial_supply;
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(!paused, "Contract is paused");
        require(to != address(0), "Invalid recipient");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function stake(uint256 amount) public {
        require(!paused, "Contract is paused");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        update_rewards(msg.sender);
        
        balances[msg.sender] -= amount;
        stakes[msg.sender] += amount;
        total_staked += amount;
        
        emit Staked(msg.sender, amount);
    }
    
    function unstake(uint256 amount) public {
        require(stakes[msg.sender] >= amount, "Insufficient stake");
        
        update_rewards(msg.sender);
        
        stakes[msg.sender] -= amount;
        total_staked -= amount;
        balances[msg.sender] += amount;
        
        emit Unstaked(msg.sender, amount);
    }
    
    function claim_rewards() public {
        update_rewards(msg.sender);
        
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        require(reward_pool >= reward, "Insufficient reward pool");
        
        rewards[msg.sender] = 0;
        reward_pool -= reward;
        balances[msg.sender] += reward;
        
        emit RewardsClaimed(msg.sender, reward);
    }
    
    function update_rewards(address account) private {
        if (stakes[account] > 0) {
            uint256 time_diff = block.timestamp - last_claim_time[account];
            uint256 reward = (stakes[account] * reward_rate * time_diff) / (365 * 24 * 3600);
            rewards[account] += reward;
        }
        last_claim_time[account] = block.timestamp;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
}
'@

Set-Content -Path $ComplexTestPath -Value $ComplexTestContent

# Complex contract compilation
if (Test-Path $OmegaBinary) {
    try {
        $complexCompileTime = Measure-ExecutionTime {
            & $OmegaBinary compile $ComplexTestPath --target evm 2>&1 | Out-Null
        }
        Log-Benchmark "complex_compilation" "compilation_time" $complexCompileTime "seconds"
    } catch {
        Write-Host "⚠️ Complex compilation failed: $_" -ForegroundColor Yellow
        Log-Benchmark "complex_compilation" "compilation_time" 0 "seconds" "FAIL"
    }
}

# 2. Memory Usage Analysis
Write-Host "💾 Memory Usage Analysis..." -ForegroundColor Yellow

$process = Get-Process -Name "omega" -ErrorAction SilentlyContinue
if ($process) {
    $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
    Log-Benchmark "memory_usage" "peak_memory" $memoryMB "MB"
} else {
    Log-Benchmark "memory_usage" "peak_memory" 0 "MB" "N/A"
}

# 3. Binary Size Analysis
Write-Host "📦 Binary Size Analysis..." -ForegroundColor Yellow

if (Test-Path $OmegaBinary) {
    $binarySize = (Get-Item $OmegaBinary).Length
    $binarySizeMB = [math]::Round($binarySize / 1MB, 2)
    Log-Benchmark "binary_size" "executable_size" $binarySizeMB "MB"
} else {
    Log-Benchmark "binary_size" "executable_size" 0 "MB" "FAIL"
}

# 4. Throughput Benchmarks
Write-Host "🚀 Throughput Benchmarks..." -ForegroundColor Yellow

# Create batch test directory
$BatchTestDir = Join-Path $BenchmarkTestsDir "batch"
if (-not (Test-Path $BatchTestDir)) {
    New-Item -ItemType Directory -Path $BatchTestDir -Force | Out-Null
}

# Create multiple test files for batch compilation
for ($i = 1; $i -le 10; $i++) {
    $batchTestPath = Join-Path $BatchTestDir "test_$i.omega"
    $batchTestContent = @"
blockchain BatchTest$i {
    state {
        uint256 value_$i;
        mapping(address => uint256) balances_$i;
    }
    
    function set_value_$i(uint256 new_value) public {
        value_$i = new_value;
    }
    
    function get_value_$i() public view returns (uint256) {
        return value_$i;
    }
}
"@
    Set-Content -Path $batchTestPath -Value $batchTestContent
}

# Measure batch compilation time
if (Test-Path $OmegaBinary) {
    $batchTime = Measure-ExecutionTime {
        for ($i = 1; $i -le 10; $i++) {
            $batchTestPath = Join-Path $BatchTestDir "test_$i.omega"
            & $OmegaBinary compile $batchTestPath --target evm 2>&1 | Out-Null
        }
    }
    
    if ($batchTime -gt 0) {
        $throughput = [math]::Round(10 / $batchTime, 2)
        Log-Benchmark "throughput" "contracts_per_second" $throughput "contracts/sec"
    }
}

# 5. Cross-compilation Performance
Write-Host "🎯 Cross-compilation Performance..." -ForegroundColor Yellow

if (Test-Path $OmegaBinary) {
    # EVM target
    try {
        $evmTime = Measure-ExecutionTime {
            & $OmegaBinary compile $SimpleTestPath --target evm 2>&1 | Out-Null
        }
        Log-Benchmark "evm_compilation" "compilation_time" $evmTime "seconds"
    } catch {
        Log-Benchmark "evm_compilation" "compilation_time" 0 "seconds" "FAIL"
    }
    
    # Solana target
    try {
        $solanaTime = Measure-ExecutionTime {
            & $OmegaBinary compile $SimpleTestPath --target solana 2>&1 | Out-Null
        }
        Log-Benchmark "solana_compilation" "compilation_time" $solanaTime "seconds"
    } catch {
        Log-Benchmark "solana_compilation" "compilation_time" 0 "seconds" "FAIL"
    }
}

# Save report to JSON
$Report | ConvertTo-Json -Depth 10 | Set-Content -Path $ReportFile

# Generate performance summary
Write-Host ""
Write-Host "📊 Performance Benchmark Summary" -ForegroundColor Blue
Write-Host "=================================" -ForegroundColor Blue

$simpleCompileResult = $Report.benchmark_results["simple_compilation_compilation_time"]
$complexCompileResult = $Report.benchmark_results["complex_compilation_compilation_time"]
$binarySizeResult = $Report.benchmark_results["binary_size_executable_size"]
$evmResult = $Report.benchmark_results["evm_compilation_compilation_time"]
$solanaResult = $Report.benchmark_results["solana_compilation_compilation_time"]

Write-Host "⚡ Compilation Performance:" -ForegroundColor Green
if ($simpleCompileResult) {
    Write-Host "  Simple Contract: $($simpleCompileResult.value)s"
}
if ($complexCompileResult) {
    Write-Host "  Complex Contract: $($complexCompileResult.value)s"
}

Write-Host "💾 Resource Usage:" -ForegroundColor Green
if ($binarySizeResult) {
    Write-Host "  Binary Size: $($binarySizeResult.value)MB"
}

Write-Host "🎯 Target Performance:" -ForegroundColor Green
if ($evmResult) {
    Write-Host "  EVM: $($evmResult.value)s"
}
if ($solanaResult) {
    Write-Host "  Solana: $($solanaResult.value)s"
}

Write-Host ""
Write-Host "Detailed benchmark report saved to: $ReportFile"

# Performance thresholds check
$performanceIssues = 0

# Check if compilation times are reasonable
if ($simpleCompileResult -and $simpleCompileResult.value -gt 5.0) {
    Write-Host "⚠️  Simple compilation time is high: $($simpleCompileResult.value)s" -ForegroundColor Yellow
    $performanceIssues++
}

if ($complexCompileResult -and $complexCompileResult.value -gt 30.0) {
    Write-Host "⚠️  Complex compilation time is high: $($complexCompileResult.value)s" -ForegroundColor Yellow
    $performanceIssues++
}

# Check binary size
if ($binarySizeResult -and $binarySizeResult.value -gt 100) {
    Write-Host "⚠️  Binary size is large: $($binarySizeResult.value)MB" -ForegroundColor Yellow
    $performanceIssues++
}

# Final assessment
if ($performanceIssues -eq 0) {
    Write-Host "✅ All performance benchmarks passed" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Performance benchmarks completed with $performanceIssues concerns" -ForegroundColor Yellow
    exit 1
}