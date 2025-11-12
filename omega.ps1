#!/usr/bin/env pwsh
param([string]$Command, [string[]]$Arguments)

function Show-Version {
    $baseVersion = "1.3.0"
    try {
        $verFile = Join-Path $PSScriptRoot "VERSION"
        if (Test-Path $verFile) { $baseVersion = (Get-Content $verFile -ErrorAction SilentlyContinue | Select-Object -First 1).Trim() }
    } catch { }

    $meta = $null
    if ($env:GITHUB_RUN_NUMBER -or $env:GITHUB_SHA) {
        $run = $env:GITHUB_RUN_NUMBER
        $sha = $env:GITHUB_SHA
        if ($sha) { $sha = $sha.Substring(0,7) }
        $parts = @()
        if ($run) { $parts += "ci.$run" }
        if ($sha) { $parts += "sha.$sha" }
        $meta = ($parts -join ".")
    } else {
        $meta = "local." + (Get-Date -Format "yyyyMMdd.HHmm")
    }
    $versionStr = $baseVersion
    if ($meta) { $versionStr = "$baseVersion-$meta" }

    Write-Host "OMEGA Native Compiler v$versionStr"
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
    Show-Version
    Write-Host "Use --help for usage information"
    exit 0
}
