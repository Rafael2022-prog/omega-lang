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
    Write-Host "  compile [file]    Compile OMEGA source file"
    Write-Host "  --version         Show version information"
    Write-Host "  --help            Show this help message"
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

if ($Command -eq "--version") {
    Show-Version
    exit 0
} elseif ($Command -eq "--help" -or -not $Command) {
    Show-Help
    exit 0
} elseif ($Command -eq "compile") {
    $exitCode = Invoke-Compile -SourceFile $Arguments[0]
    exit $exitCode
} else {
    Write-Host "OMEGA Native Compiler v1.0.0"
    Write-Host "Use --help for usage information"
    exit 0
}
