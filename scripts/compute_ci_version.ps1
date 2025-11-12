param(
    [string]$DefaultBase = "1.3.0"
)

$ErrorActionPreference = 'Stop'

function Get-BaseVersion {
    param([string]$Fallback)
    try {
        # Resolve repository root relative to this script
        $scriptDir = Split-Path -Parent $PSCommandPath
        $repoRoot = Resolve-Path (Join-Path $scriptDir '..')
        $versionFile = Join-Path $repoRoot 'VERSION'
        if (Test-Path $versionFile) {
            $line = (Get-Content -LiteralPath $versionFile -TotalCount 1 | Select-Object -First 1)
            if ($line) { return $line.Trim() }
        }
        return $Fallback
    } catch {
        return $Fallback
    }
}

$base = Get-BaseVersion -Fallback $DefaultBase

# Compose CI/local metadata
if ($env:GITHUB_RUN_NUMBER -and $env:GITHUB_SHA) {
    $meta = "ci.$($env:GITHUB_RUN_NUMBER)." + $env:GITHUB_SHA.Substring(0,7)
} else {
    $meta = "local." + (Get-Date).ToString("yyyyMMdd.HHmm")
}

$full = "$base-$meta"

# Export to GitHub Actions outputs/env if available
try {
    if ($env:GITHUB_OUTPUT) {
        "version=$full" >> $env:GITHUB_OUTPUT
    }
    if ($env:GITHUB_ENV) {
        "OMEGA_VERSION_NAME=$full" >> $env:GITHUB_ENV
    }
} catch {
    Write-Host "[warn] Failed to write GitHub outputs/env: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

Write-Host "OMEGA CI Version: $full" -ForegroundColor Cyan

# Return the computed version (useful for local runs)
$full