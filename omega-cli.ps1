#!/usr/bin/env pwsh
# Enhanced OMEGA CLI Wrapper - Cross-Platform Build System
# Supports: compile, build, test, deploy, and platform detection

param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    
    [Parameter(Position=1)]
    [string]$Target = "",
    
    [Parameter(Position=2)]
    [string]$Network = "",
    
    [switch]$Help,
    [switch]$Version,
    [switch]$Verbose,
    [switch]$Force
)

# Global Configuration
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$OMEGA_BINARY = Join-Path $PROJECT_ROOT "omega"
$CONFIG_FILE = Join-Path $PROJECT_ROOT "omega.toml"
$BUILD_DIR = Join-Path $PROJECT_ROOT "build"
$TEST_DIR = Join-Path $PROJECT_ROOT "tests"
$DEPLOY_DIR = Join-Path $PROJECT_ROOT "deployment"

# Platform Detection
$PLATFORM = ""
$ARCH = ""
$IS_WINDOWS = $false
$IS_LINUX = $false
$IS_MACOS = $false

function Initialize-Platform {
    $platform = [System.Environment]::OSVersion.Platform
    $arch = [System.Environment]::Is64BitOperatingSystem ? "x64" : "x86"
    
    switch ($platform) {
        "Win32NT" { 
            $script:PLATFORM = "windows"
            $script:ARCH = $arch
            $script:IS_WINDOWS = $true
            $script:OMEGA_BINARY = "$OMEGA_BINARY.exe"
        }
        "Unix" {
            if ($env:OS -eq "Linux") {
                $script:PLATFORM = "linux"
                $script:IS_LINUX = $true
            } elseif ($env:OS -eq "Darwin") {
                $script:PLATFORM = "macos"
                $script:IS_MACOS = $true
            }
            $script:ARCH = $arch
        }
        default {
            Write-Error "Unsupported platform: $platform"
            exit 1
        }
    }
    
    if ($Verbose) {
        Write-Host "Platform: $PLATFORM ($ARCH)" -ForegroundColor Cyan
    }
}

# Cross-Platform Path Utilities
function Get-NativePath {
    param([string]$Path)
    
    if ($IS_WINDOWS) {
        return $Path -replace "/", "\"
    } else {
        return $Path -replace "\\", "/"
    }
}

function Test-CommandExists {
    param([string]$Command)
    
    try {
        if ($IS_WINDOWS) {
            $null = Get-Command $Command -ErrorAction Stop
        } else {
            $null = which $Command 2>/dev/null
        }
        return $true
    } catch {
        return $false
    }
}

# OMEGA Binary Management
function Test-OmegaBinary {
    if (-not (Test-Path $OMEGA_BINARY)) {
        Write-Error "OMEGA binary not found at: $OMEGA_BINARY"
        Write-Host "Please build OMEGA first using: ./build.ps1" -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Get-OmegaVersion {
    if (Test-OmegaBinary) {
        try {
            $version = & $OMEGA_BINARY --version 2>$null
            return $version
        } catch {
            return "unknown"
        }
    }
    return "not-installed"
}

# Build System
function Invoke-OmegaCompile {
    param(
        [string]$SourceFile,
        [string]$OutputDir = $BUILD_DIR,
        [string]$Target = "evm"
    )
    
    Write-Host "🔨 Compiling OMEGA source: $SourceFile" -ForegroundColor Green
    
    if (-not (Test-Path $SourceFile)) {
        Write-Error "Source file not found: $SourceFile"
        return $false
    }
    
    # Create output directory
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    # Compile command
    $outputFile = Join-Path $OutputDir ([System.IO.Path]::GetFileNameWithoutExtension($SourceFile))
    
    try {
        $compileArgs = @(
            "compile",
            $SourceFile,
            "--target", $Target,
            "--output", $outputFile
        )
        
        if ($Verbose) {
            Write-Host "Executing: $OMEGA_BINARY $compileArgs" -ForegroundColor Gray
        }
        
        & $OMEGA_BINARY $compileArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Compilation successful: $outputFile" -ForegroundColor Green
            return $true
        } else {
            Write-Error "Compilation failed with exit code: $LASTEXITCODE"
            return $false
        }
    } catch {
        Write-Error "Compilation error: $_"
        return $false
    }
}

function Invoke-OmegaBuild {
    param(
        [string]$ProjectDir = ".",
        [string]$Target = "evm",
        [switch]$Clean
    )
    
    Write-Host "🏗️  Building OMEGA project: $ProjectDir" -ForegroundColor Green
    
    # Clean build directory if requested
    if ($Clean -and (Test-Path $BUILD_DIR)) {
        Remove-Item $BUILD_DIR -Recurse -Force
        Write-Host "🧹 Cleaned build directory" -ForegroundColor Yellow
    }
    
    # Find all .omega files in project
    $omegaFiles = Get-ChildItem -Path $ProjectDir -Filter "*.omega" -Recurse
    
    if ($omegaFiles.Count -eq 0) {
        Write-Warning "No .omega files found in project directory"
        return $false
    }
    
    Write-Host "Found $($omegaFiles.Count) OMEGA source files" -ForegroundColor Cyan
    
    $successCount = 0
    foreach ($file in $omegaFiles) {
        if (Invoke-OmegaCompile -SourceFile $file.FullName -Target $Target) {
            $successCount++
        }
    }
    
    Write-Host "Built $successCount/$($omegaFiles.Count) files successfully" -ForegroundColor $(
        $successCount -eq $omegaFiles.Count ? "Green" : "Yellow"
    )
    
    return $successCount -eq $omegaFiles.Count
}

# Testing System
function Invoke-OmegaTest {
    param(
        [string]$TestDir = $TEST_DIR,
        [string]$Pattern = "*.test.omega",
        [switch]$Verbose
    )
    
    Write-Host "🧪 Running OMEGA tests" -ForegroundColor Green
    
    if (-not (Test-Path $TestDir)) {
        Write-Warning "Test directory not found: $TestDir"
        return $false
    }
    
    # Find test files
    $testFiles = Get-ChildItem -Path $TestDir -Filter $Pattern -Recurse
    
    if ($testFiles.Count -eq 0) {
        Write-Warning "No test files found matching pattern: $Pattern"
        return $false
    }
    
    Write-Host "Found $($testFiles.Count) test files" -ForegroundColor Cyan
    
    $passed = 0
    $failed = 0
    
    foreach ($testFile in $testFiles) {
        Write-Host "Running test: $($testFile.Name)" -ForegroundColor Gray
        
        # Compile test file
        $testOutput = Join-Path $BUILD_DIR "tests" $testFile.Name
        $compileSuccess = Invoke-OmegaCompile -SourceFile $testFile.FullName -OutputDir (Split-Path $testOutput -Parent)
        
        if ($compileSuccess) {
            $passed++
            Write-Host "✅ PASSED: $($testFile.Name)" -ForegroundColor Green
        } else {
            $failed++
            Write-Host "❌ FAILED: $($testFile.Name)" -ForegroundColor Red
        }
    }
    
    Write-Host "Test Results: $passed passed, $failed failed" -ForegroundColor $(
        $failed -eq 0 ? "Green" : "Yellow"
    )
    
    return $failed -eq 0
}

# Help System
function Show-Help {
    Write-Host @"
🎯 OMEGA Enhanced CLI - Cross-Platform Build System

USAGE:
    omega-cli.ps1 [COMMAND] [OPTIONS]

COMMANDS:
    compile <file> [--target <target>]     Compile OMEGA source file
    build [--target <target>] [--clean]     Build entire project
    test [--pattern <pattern>]              Run test suite
    deploy <file> [--network <network>]   Deploy to blockchain
    config                                  Show configuration
    version                                 Show version info
    help                                    Show this help

OPTIONS:
    --target <target>     Compilation target (evm, solana, etc.)
    --network <network>   Deployment network (localhost, testnet, mainnet)
    --clean               Clean build before building
    --verbose             Verbose output
    --force               Force operation

EXAMPLES:
    # Compile single file
    ./omega-cli.ps1 compile contracts/SimpleToken.omega --target evm
    
    # Build entire project
    ./omega-cli.ps1 build --target evm --clean
    
    # Run tests
    ./omega-cli.ps1 test --pattern "*.test.omega"
    
    # Deploy contract
    ./omega-cli.ps1 deploy contracts/SimpleToken.omega --network sepolia

PLATFORMS:
    ✅ Windows (Native)
    🚧 Linux (In Development)
    🚧 macOS (In Development)

TARGETS:
    ✅ EVM (Ethereum, Polygon, BSC)
    🚧 Solana (Planned)
    🚧 Cosmos (Planned)
    🚧 Move VM (Planned)

"@ -ForegroundColor Cyan
}

# Main Execution
function Main {
    # Initialize platform detection
    Initialize-Platform
    
    # Handle version and help flags
    if ($Version) {
        $version = Get-OmegaVersion
        Write-Host "OMEGA CLI Version: 1.0.0" -ForegroundColor Green
        Write-Host "OMEGA Binary Version: $version" -ForegroundColor Cyan
        return
    }
    
    if ($Help -or $Command -eq "help") {
        Show-Help
        return
    }
    
    # Validate OMEGA binary
    if (-not (Test-OmegaBinary)) {
        exit 1
    }
    
    # Execute command
    switch ($Command.ToLower()) {
        "compile" {
            if (-not $Target) {
                Write-Error "Please specify source file to compile"
                exit 1
            }
            Invoke-OmegaCompile -SourceFile $Target
        }
        "build" {
            Invoke-OmegaBuild -Target $Target -Clean:$Clean
        }
        "test" {
            Invoke-OmegaTest -Pattern $Pattern -Verbose:$Verbose
        }
        "deploy" {
            if (-not $Target) {
                Write-Error "Please specify contract file to deploy"
                exit 1
            }
            if (-not $Network) { $Network = "localhost" }
            Write-Host "Deploy functionality coming soon!" -ForegroundColor Yellow
            Write-Host "Would deploy: $Target to network: $Network" -ForegroundColor Cyan
        }
        "config" {
            Write-Host "OMEGA Binary: $OMEGA_BINARY" -ForegroundColor Cyan
            Write-Host "Platform: $PLATFORM ($ARCH)" -ForegroundColor Cyan
        }
        "version" {
            $version = Get-OmegaVersion
            Write-Host "OMEGA CLI: 1.0.0" -ForegroundColor Green
            Write-Host "OMEGA Binary: $version" -ForegroundColor Cyan
        }
        default {
            Write-Error "Unknown command: $Command"
            Show-Help
            exit 1
        }
    }
}

# Error Handling
trap {
    Write-Error "Unexpected error: $_"
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}

# Execute main function
Main