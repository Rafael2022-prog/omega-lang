# OMEGA Enhanced Benchmark Suite
# PowerShell script untuk menjalankan benchmark komprehensif multi-target

param(
    [string]$OutputDir = "benchmark-results",
    [int]$Iterations = 20,
    [string[]]$Targets = @("evm", "solana", "cosmos", "substrate"),
    [switch]$StatisticalAnalysis = $true,
    [switch]$MemoryProfiling = $true,
    [switch]$RegressionDetection = $true,
    [string]$BaselineFile = "baseline-metrics.json",
    [switch]$GenerateReport = $true,
    [switch]$UploadResults = $false
)

# Enhanced configuration with performance optimizations
$Config = @{
    OutputDir = $OutputDir
    Iterations = $Iterations
    Targets = $Targets
    StatisticalAnalysis = $StatisticalAnalysis
    MemoryProfiling = $MemoryProfiling
    RegressionDetection = $RegressionDetection
    BaselineFile = $BaselineFile
    GenerateReport = $GenerateReport
    UploadResults = $UploadResults
    
    # Performance thresholds
    MaxCompilationTime = 15  # seconds (reduced from 30)
    MemoryLimitMB = 1024     # MB (reduced from 4096)
    MinCacheHitRatio = 90    # percentage
    MinParallelEfficiency = 85 # percentage
    
    # Statistical parameters
    ConfidenceInterval = 95
    OutlierThreshold = 2.0   # standard deviations
    MinSampleSize = 20
    
    # Optimization flags
    RustFlags = "-C opt-level=3 -C target-cpu=native"
    BuildJobs = 8
    RuntimeOptimizations = $true
}

# System information collection
function Get-SystemInfo {
    $cpu = Get-WmiObject -Class Win32_Processor
    $memory = Get-WmiObject -Class Win32_ComputerSystem
    $os = Get-WmiObject -Class Win32_OperatingSystem
    
    return @{
        CPU = $cpu.Name
        Cores = $cpu.NumberOfCores
        LogicalProcessors = $cpu.NumberOfLogicalProcessors
        TotalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
        OSVersion = $os.Caption
        Architecture = $os.OSArchitecture
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Enhanced timing function with statistical analysis
function Measure-EnhancedExecutionTime {
    param(
        [scriptblock]$ScriptBlock,
        [int]$Iterations = 20,
        [int]$WarmupIterations = 5
    )
    
    $times = @()
    $memoryUsages = @()
    
    Write-Host "🔄 Running warmup iterations..." -ForegroundColor Yellow
    for ($i = 1; $i -le $WarmupIterations; $i++) {
        & $ScriptBlock | Out-Null
        Write-Progress -Activity "Warmup" -Status "Iteration $i/$WarmupIterations" -PercentComplete ($i/$WarmupIterations*100)
    }
    
    Write-Host "📊 Running measurement iterations..." -ForegroundColor Green
    for ($i = 1; $i -le $Iterations; $i++) {
        $startMemory = [GC]::GetTotalMemory($true)
        $startTime = [DateTime]::UtcNow
        
        $result = & $ScriptBlock
        
        $endTime = [DateTime]::UtcNow
        $endMemory = [GC]::GetTotalMemory($true)
        
        $executionTime = ($endTime - $startTime).TotalMilliseconds
        $memoryUsage = ($endMemory - $startMemory) / 1MB
        
        $times += $executionTime
        $memoryUsages += $memoryUsage
        
        Write-Progress -Activity "Benchmark" -Status "Iteration $i/$Iterations" -PercentComplete ($i/$Iterations*100)
    }
    
    # Statistical analysis
    $stats = Get-StatisticalAnalysis -Data $times
    $memoryStats = Get-StatisticalAnalysis -Data $memoryUsages
    
    return @{
        ExecutionTimes = $times
        MemoryUsages = $memoryUsages
        Statistics = $stats
        MemoryStatistics = $memoryStats
        RawResult = $result
    }
}

# Statistical analysis function
function Get-StatisticalAnalysis {
    param([double[]]$Data)
    
    $sorted = $Data | Sort-Object
    $n = $Data.Count
    
    # Basic statistics
    $mean = ($Data | Measure-Object -Average).Average
    $median = if ($n % 2 -eq 0) {
        ($sorted[$n/2-1] + $sorted[$n/2]) / 2
    } else {
        $sorted[($n-1)/2]
    }
    
    # Variance and standard deviation
    $variance = ($Data | ForEach-Object { [math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
    $stdDev = [math]::Sqrt($variance)
    
    # Percentiles
    $p25 = Get-Percentile -Data $sorted -Percentile 25
    $p75 = Get-Percentile -Data $sorted -Percentile 75
    $p95 = Get-Percentile -Data $sorted -Percentile 95
    $p99 = Get-Percentile -Data $sorted -Percentile 99
    
    # Outlier detection
    $q1 = $p25
    $q3 = $p75
    $iqr = $q3 - $q1
    $lowerFence = $q1 - 1.5 * $iqr
    $upperFence = $q3 + 1.5 * $iqr
    
    $outliers = $Data | Where-Object { $_ -lt $lowerFence -or $_ -gt $upperFence }
    $outlierCount = $outliers.Count
    
    return @{
        SampleSize = $n
        Mean = $mean
        Median = $median
        StandardDeviation = $stdDev
        Variance = $variance
        Min = ($Data | Measure-Object -Minimum).Minimum
        Max = ($Data | Measure-Object -Maximum).Maximum
        Q1 = $p25
        Q3 = $p75
        P95 = $p95
        P99 = $p99
        Outliers = $outliers
        OutlierCount = $outlierCount
        OutlierPercentage = ($outlierCount / $n) * 100
        CoefficientOfVariation = ($stdDev / $mean) * 100
    }
}

# Percentile calculation
function Get-Percentile {
    param([double[]]$Data, [int]$Percentile)
    
    $n = $Data.Count
    $index = ($Percentile / 100) * ($n - 1)
    $lower = [math]::Floor($index)
    $upper = [math]::Ceiling($index)
    
    if ($lower -eq $upper) {
        return $Data[$lower]
    } else {
        $weight = $index - $lower
        return $Data[$lower] * (1 - $weight) + $Data[$upper] * $weight
    }
}

# Enhanced compilation benchmark
function Test-EnhancedCompilation {
    param([string]$Target)
    
    Write-Host "🚀 Testing enhanced compilation for $Target..." -ForegroundColor Cyan
    
    $testContracts = @{
        "simple" = @"
blockchain SimpleContract {
    state { uint256 value; }
    constructor() { value = 42; }
    function get() public view returns (uint256) { return value; }
}
"@
        "complex" = @"
blockchain ComplexContract {
    state {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 total_supply;
        string name;
        string symbol;
    }
    
    constructor(string _name, string _symbol, uint256 _supply) {
        name = _name;
        symbol = _symbol;
        total_supply = _supply;
        balances[msg.sender] = _supply;
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
}
"@
    }
    
    $results = @{}
    
    foreach ($contractType in $testContracts.Keys) {
        Write-Host "📄 Compiling $contractType contract..." -ForegroundColor Yellow
        
        $contractCode = $testContracts[$contractType]
        $tempFile = [System.IO.Path]::GetTempFileName() + ".mega"
        $contractCode | Out-File -FilePath $tempFile -Encoding UTF8
        
        $benchmark = Measure-EnhancedExecutionTime -ScriptBlock {
            $output = & omega compile --target $Target --output temp $tempFile 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Compilation failed: $output"
            }
            return $output
        } -Iterations $Config.Iterations
        
        $results[$contractType] = $benchmark
        
        # Cleanup
        if (Test-Path $tempFile) { Remove-Item $tempFile }
        if (Test-Path "temp") { Remove-Item -Recurse -Force "temp" }
    }
    
    return $results
}

# Performance regression detection
function Test-PerformanceRegression {
    param([hashtable]$CurrentResults, [string]$BaselineFile)
    
    if (-not (Test-Path $BaselineFile)) {
        Write-Host "⚠️  Baseline file not found, creating new baseline..." -ForegroundColor Yellow
        $CurrentResults | ConvertTo-Json -Depth 10 | Out-File $BaselineFile
        return @{ HasRegression = $false; Regressions = @() }
    }
    
    $baseline = Get-Content $BaselineFile | ConvertFrom-Json
    $regressions = @()
    
    foreach ($target in $CurrentResults.Keys) {
        if ($baseline.$target) {
            $currentMean = $CurrentResults[$target].Statistics.Mean
            $baselineMean = $baseline.$target.Statistics.Mean
            
            $percentageChange = (($currentMean - $baselineMean) / $baselineMean) * 100
            
            if ($percentageChange -gt 5) { # 5% threshold
                $regressions += @{
                    Target = $target
                    Baseline = $baselineMean
                    Current = $currentMean
                    PercentageChange = $percentageChange
                    Severity = if ($percentageChange -gt 20) { "High" } elseif ($percentageChange -gt 10) { "Medium" } else { "Low" }
                }
            }
        }
    }
    
    return @{
        HasRegression = $regressions.Count -gt 0
        Regressions = $regressions
    }
}

# Generate comprehensive report
function New-ComprehensiveReport {
    param([hashtable]$Results, [hashtable]$SystemInfo, [hashtable]$RegressionAnalysis)
    
    $report = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        SystemInfo = $SystemInfo
        Configuration = $Config
        Results = $Results
        RegressionAnalysis = $RegressionAnalysis
        Summary = @{}
    }
    
    # Calculate summary statistics
    $totalTests = 0
    $totalTime = 0
    $targetSummaries = @{}
    
    foreach ($target in $Results.Keys) {
        $targetResults = $Results[$target]
        $simpleStats = $targetResults.simple.Statistics
        $complexStats = $targetResults.complex.Statistics
        
        $targetSummaries[$target] = @{
            SimpleContract = @{
                MeanTime = $simpleStats.Mean
                MemoryUsage = $targetResults.simple.MemoryStatistics.Mean
                ConfidenceInterval = $simpleStats.Mean * 1.96 * ($simpleStats.StandardDeviation / [math]::Sqrt($simpleStats.SampleSize))
            }
            ComplexContract = @{
                MeanTime = $complexStats.Mean
                MemoryUsage = $targetResults.complex.MemoryStatistics.Mean
                ConfidenceInterval = $complexStats.Mean * 1.96 * ($complexStats.StandardDeviation / [math]::Sqrt($complexStats.SampleSize))
            }
            PerformanceScore = 100 - (($complexStats.Mean - $simpleStats.Mean) / $simpleStats.Mean) * 10
        }
        
        $totalTests += 2
        $totalTime += $simpleStats.Mean + $complexStats.Mean
    }
    
    $report.Summary = @{
        TotalTargets = $Results.Keys.Count
        TotalTests = $totalTests
        AverageCompilationTime = $totalTime / $totalTests
        TargetSummaries = $targetSummaries
        OverallPerformanceScore = ($targetSummaries.Values | ForEach-Object { $_.PerformanceScore } | Measure-Object -Average).Average
    }
    
    return $report
}

# Main execution
function Invoke-EnhancedBenchmark {
    Write-Host "🎯 OMEGA Enhanced Benchmark Suite" -ForegroundColor Magenta
    Write-Host "=====================================" -ForegroundColor Magenta
    
    # Setup
    if (-not (Test-Path $Config.OutputDir)) {
        New-Item -ItemType Directory -Path $Config.OutputDir | Out-Null
    }
    
    $systemInfo = Get-SystemInfo
    Write-Host "💻 System: $($systemInfo.CPU)" -ForegroundColor Cyan
    Write-Host "🧠 Memory: $($systemInfo.TotalMemoryGB)GB" -ForegroundColor Cyan
    Write-Host "🔧 Targets: $($Config.Targets -join ', ')" -ForegroundColor Cyan
    Write-Host "📊 Iterations: $($Config.Iterations)" -ForegroundColor Cyan
    
    # Run benchmarks
    $allResults = @{}
    
    foreach ($target in $Config.Targets) {
        Write-Host "`n🎯 Benchmarking $target target..." -ForegroundColor Green
        $targetResults = Test-EnhancedCompilation -Target $target
        $allResults[$target] = $targetResults
    }
    
    # Regression analysis
    $regressionAnalysis = @{ HasRegression = $false; Regressions = @() }
    if ($Config.RegressionDetection) {
        Write-Host "🔍 Performing regression analysis..." -ForegroundColor Yellow
        $regressionAnalysis = Test-PerformanceRegression -CurrentResults $allResults -BaselineFile $Config.BaselineFile
    }
    
    # Generate report
    if ($Config.GenerateReport) {
        Write-Host "📋 Generating comprehensive report..." -ForegroundColor Blue
        $report = New-ComprehensiveReport -Results $allResults -SystemInfo $systemInfo -RegressionAnalysis $regressionAnalysis
        
        $reportFile = Join-Path $Config.OutputDir "enhanced-benchmark-report.json"
        $report | ConvertTo-Json -Depth 15 | Out-File $reportFile
        
        Write-Host "✅ Report saved to: $reportFile" -ForegroundColor Green
        
        # Display summary
        Write-Host "`n📈 Benchmark Summary" -ForegroundColor Magenta
        Write-Host "=====================" -ForegroundColor Magenta
        Write-Host "Overall Performance Score: $($report.Summary.OverallPerformanceScore.ToString('F1'))/100" -ForegroundColor White
        Write-Host "Average Compilation Time: $($report.Summary.AverageCompilationTime.ToString('F2'))ms" -ForegroundColor White
        
        if ($regressionAnalysis.HasRegression) {
            Write-Host "⚠️  Performance regressions detected!" -ForegroundColor Red
            foreach ($regression in $regressionAnalysis.Regressions) {
                Write-Host "   Target: $($regression.Target) - $($regression.PercentageChange.ToString('F1'))% ($($regression.Severity) severity)" -ForegroundColor Red
            }
        } else {
            Write-Host "✅ No performance regressions detected" -ForegroundColor Green
        }
    }
    
    Write-Host "`n🎉 Enhanced benchmark suite completed!" -ForegroundColor Green
}

# Execute the benchmark
Invoke-EnhancedBenchmark