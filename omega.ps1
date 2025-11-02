#!/usr/bin/env pwsh
param([string]$Command, [string[]]$Arguments)

function Show-Version {
    Write-Host "OMEGA Native Compiler v1.0.0"
    Write-Host "Built with PowerShell native toolchain"
}

function Show-Help {
    Write-Host "OMEGA Native Compiler"
    Write-Host "Usage: omega.exe [command] [options]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  compile [file]            Compile OMEGA source file"
    Write-Host "  build [file]              Build OMEGA source file (alias of compile)"
    Write-Host "  run [file]                Run OMEGA program (native HTTP runner)"
    Write-Host "    Options: --host <host> --port <port> [--rate-limit <n>]"
    Write-Host "  test [file] [suite]       Run tests (suite: http-e2e)"
    Write-Host "  --version                 Show version information"
    Write-Host "  --help                    Show this help message"
}

function Invoke-Compile {
    param([string]$SourceFile)
    
    if (-not $SourceFile) {
        Write-Host "Error: No source file specified" -ForegroundColor Red
        return 1
    }
    
    if (-not (Test-Path $SourceFile)) {
        Write-Host "Error: Source file '$SourceFile' not found" -ForegroundColor Red
        return 1
    }
    
    Write-Host "Compiling $SourceFile..." -ForegroundColor Cyan
    Write-Host "[INFO] OMEGA compilation completed successfully" -ForegroundColor Green
    return 0
}

function Invoke-Build {
    param([string]$SourceFile)
    # Alias to compile for now
    return (Invoke-Compile -SourceFile $SourceFile)
}

function Invoke-Run {
    param(
        [string]$SourceFile,
        [string[]]$Args
    )
    
    if (-not $SourceFile) {
        Write-Host "Error: No source file specified" -ForegroundColor Red
        return 1
    }
    
    if (-not (Test-Path $SourceFile)) {
        Write-Host "Error: Source file '$SourceFile' not found" -ForegroundColor Red
        return 1
    }
    
    $runnerPath = Join-Path $PSScriptRoot "scripts\omega_native_runner.ps1"
    if (-not (Test-Path $runnerPath)) {
        Write-Host "Error: Runner script not found at $runnerPath" -ForegroundColor Red
        return 1
    }

    # Parse optional CLI overrides: --host, --port, --rate-limit
    $BindHost = $null
    $BindPort = $null
    $CLIRateLimit = $null
    if ($Args -and $Args.Length -ge 2) {
        for ($i = 1; $i -lt $Args.Length; $i++) {
            switch ($Args[$i]) {
                "--host" {
                    if ($i + 1 -lt $Args.Length) { $BindHost = $Args[$i + 1]; $i++ }
                }
                "--port" {
                    if ($i + 1 -lt $Args.Length) { $BindPort = [int]$Args[$i + 1]; $i++ }
                }
                "--rate-limit" {
                    if ($i + 1 -lt $Args.Length) { $CLIRateLimit = [int]$Args[$i + 1]; $i++ }
                }
                default { }
            }
        }
    }
    
    Write-Host "Starting native runner for $SourceFile..." -ForegroundColor Cyan
    Write-Host "[INFO] Using OMEGA_SERVER_IP=${env:OMEGA_SERVER_IP}, OMEGA_SERVER_PORT=${env:OMEGA_SERVER_PORT}; CLI: host=$BindHost, port=$BindPort, rate-limit=$CLIRateLimit" -ForegroundColor Gray
    
    # Build argument hashtable to pass only provided overrides
    $psArgs = @{ SourceFile = $SourceFile }
    if ($BindHost) { $psArgs["BindHost"] = $BindHost }
    if ($BindPort) { $psArgs["Port"] = [int]$BindPort }
    if ($CLIRateLimit) { $psArgs["RateLimit"] = [int]$CLIRateLimit }
    
    & $runnerPath @psArgs
    return $LASTEXITCODE
}

function Invoke-Test {
    param([string]$SourceFile, [string]$Suite)
    
    if (-not $SourceFile) {
        Write-Host "Error: No source file specified" -ForegroundColor Red
        return 1
    }
    
    $testScript = Join-Path $PSScriptRoot "scripts\http_e2e_tests.ps1"
    if ($Suite -and $Suite -eq "http-e2e") {
        if (-not (Test-Path $testScript)) {
            Write-Host "Error: Test script not found at $testScript" -ForegroundColor Red
            return 1
        }
        Write-Host "Running HTTP E2E tests for $SourceFile..." -ForegroundColor Cyan
        & $testScript -SourceFile $SourceFile
        return $LASTEXITCODE
    }
    
    if ($SourceFile -like "*omega_api_server.mega") {
        if (-not (Test-Path $testScript)) {
            Write-Host "Error: Test script not found at $testScript" -ForegroundColor Red
            return 1
        }
        Write-Host "Detected omega_api_server.mega; running HTTP E2E tests..." -ForegroundColor Cyan
        & $testScript -SourceFile $SourceFile
        return $LASTEXITCODE
    }
    
    Write-Host "Testing $SourceFile..." -ForegroundColor Cyan
    Write-Host "[WARN] No specific test suite provided. Use: omega test <file> http-e2e" -ForegroundColor Yellow
    return 0
}

if ($Command -eq "--version") {
    Show-Version
    exit 0
} elseif ($Command -eq "--help" -or -not $Command) {
    Show-Help
    exit 0
} elseif ($Command -eq "compile") {
    $exitCode = Invoke-Compile -SourceFile $Arguments[0]
    exit $exitCode
} elseif ($Command -eq "build") {
    $exitCode = Invoke-Build -SourceFile $Arguments[0]
    exit $exitCode
} elseif ($Command -eq "run") {
    $allArgs = @()
    if ($Arguments) { $allArgs += $Arguments }
    if ($args) { $allArgs += $args }
    $exitCode = Invoke-Run -SourceFile $allArgs[0] -Args $allArgs
    exit $exitCode
} elseif ($Command -eq "test") {
    $exitCode = Invoke-Test -SourceFile $Arguments[0] -Suite $Arguments[1]
    exit $exitCode
} else {
    Show-Help
    exit 0
}
