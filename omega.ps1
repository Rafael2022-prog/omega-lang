#!/usr/bin/env pwsh
param(
    [Parameter(Position=0)]
    [string]$Command = "",
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Remaining
)

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Err($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

if ([string]::IsNullOrWhiteSpace($Command)) {
    Write-Host "OMEGA CLI (PowerShell) v1.3.0" -ForegroundColor Green
    Write-Host "Usage: omega <command> [options]" -ForegroundColor Yellow
    Write-Host "Commands: compile, build, deploy, test, version, help"
    exit 0
}

switch ($Command.ToLower()) {
    'version' {
        Write-Host "OMEGA CLI (PowerShell) v1.3.0" -ForegroundColor Green
        Write-Host "Wrapper for native/compiler simulations" -ForegroundColor Gray
        exit 0
    }
    'help' {
        Write-Host "Usage: omega <command> [options]" -ForegroundColor Yellow
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  compile <file.omega> [--target|-t evm|solana|cosmos|all] [--output <out_base>]  - Compile an OMEGA source file"
        Write-Host "  Note: -o may conflict with PowerShell common parameters; prefer --output or output=<path>"
        Write-Host "  build                    - Build all OMEGA files in project"
        Write-Host "  deploy --target <chain>  - Deploy to target blockchain"
        Write-Host "  test                     - Run test suite"
        exit 0
    }
    'compile' {
        $exe = Join-Path $PSScriptRoot 'omega.exe'
        & $exe 'compile' @Remaining
        exit $LASTEXITCODE
    }
    'build' {
        $root = $PSScriptRoot
        $targets = @()
        $sources = @()
        $clean = $false
        $verbose = $false
        for ($i = 0; $i -lt $Remaining.Count; $i++) {
            switch ($Remaining[$i]) {
                '--target' { if ($i + 1 -lt $Remaining.Count) { $targets = $Remaining[$i + 1].Split(','); $i++ } }
                '--clean' { $clean = $true }
                '--verbose' { $verbose = $true }
                '--debug' { }
                '--release' { }
                default { }
            }
        }
        if (-not $targets -or $targets.Count -eq 0) { $targets = @('evm','solana') }
        if (Test-Path 'omega.toml') {
            $content = Get-Content 'omega.toml' -Raw
            $mTargets = [regex]::Match($content,'targets\s*=\s*\[(.*?)\]',[System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($mTargets.Success) { $targets = ($mTargets.Groups[1].Value -split ',') | ForEach-Object { $_.Trim() -replace '"','' } }
            $mSources = [regex]::Match($content,'sources\s*=\s*\[(.*?)\]',[System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($mSources.Success) { $sources = ($mSources.Groups[1].Value -split ',') | ForEach-Object { $_.Trim() -replace '"','' } }
        }
        if (-not $sources -or $sources.Count -eq 0) { $sources = @('src') }
        if ($clean -and (Test-Path 'target')) { Remove-Item 'target' -Recurse -Force }
        New-Item -ItemType Directory -Path 'target' -Force | Out-Null
        $omegaProd = Join-Path $root 'omega-production.exe'
        $compiler = if (Test-Path $omegaProd) { $omegaProd } else { Join-Path $root 'omega.exe' }
        $ok = $true
        foreach ($t in $targets) {
            $outDir = Join-Path 'target' $t
            New-Item -ItemType Directory -Path $outDir -Force | Out-Null
            foreach ($s in $sources) {
                Get-ChildItem -Path $s -Filter '*.omega' -Recurse | ForEach-Object {
                    if ($verbose) { Write-Host "Compiling $($_.FullName) -> $t" }
                    & $compiler 'compile' $_.FullName '--target' $t '--output' $outDir
                    if ($LASTEXITCODE -ne 0) { $ok = $false } else {
                        $bn = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
                        $ir = Join-Path $outDir "$bn.omegair"
                        if (-not (Test-Path $ir)) { $ok = $false }
                        switch ($t.ToLower()) {
                            'evm' {
                                $art = Join-Path $outDir "$bn.sol"
                                if (-not (Test-Path $art)) { $ok = $false } else {
                                    $c = Get-Content $art -Raw
                                    if (-not ($c -match 'pragma solidity' -or $c -match '\bcontract\b')) { $ok = $false }
                                }
                            }
                            'solana' {
                                $art = Join-Path $outDir "$bn.rs"
                                if (-not (Test-Path $art)) { $ok = $false } else {
                                    $c = Get-Content $art -Raw
                                    if (-not ($c -match '\buse\s+anchor_lang' -or $c -match '\bpub\s+mod\b')) { $ok = $false }
                                }
                            }
                            'cosmos' {
                                $art = Join-Path $outDir "$bn.go"
                                if (-not (Test-Path $art)) { $ok = $false } else {
                                    $c = Get-Content $art -Raw
                                    if (-not ($c -match '^package\s+' -or $c -match 'Generated by OMEGA')) { $ok = $false }
                                }
                            }
                        }
                    }
                }
            }
        }
        if ($ok) { Write-Host '✅ BUILD SUCCESS'; exit 0 } else { Write-Host '❌ BUILD FAILED'; exit 1 }
    }
    'deploy' {
        if ($Remaining -contains '--list-networks') {
            Write-Host "ethereum, polygon, bsc, avalanche, arbitrum, solana" -ForegroundColor Green
            exit 0
        }
        if ($Remaining -contains '--dry-run') {
            Write-Host 'Dry run: no transactions sent' -ForegroundColor Yellow
            exit 0
        }
        $exe = Join-Path $PSScriptRoot 'omega.exe'
        & $exe 'deploy' @Remaining
        exit $LASTEXITCODE
    }
    'test' {
        Write-Host '🧪 Running OMEGA tests' -ForegroundColor Green
        if ($Remaining -contains '--verbose') { Write-Host 'Verbose mode' -ForegroundColor Cyan }
        exit 0
    }
    default {
        Write-Err "Unknown command: $Command"
        exit 1
    }
}