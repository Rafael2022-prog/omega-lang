# OMEGA Compiler v1.0.0 - Production Wrapper
# This script redirects to the production omega.exe executable

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

# Path to production executable
$OmegaCmd = Join-Path $PSScriptRoot "target\release\omega.cmd"

# Check if executable exists
if (!(Test-Path $OmegaCmd)) {
    Write-Error "OMEGA executable not found at: $OmegaCmd"
    Write-Host "Please run build script to generate omega.cmd" -ForegroundColor Yellow
    exit 1
}

# Forward all arguments to production executable
try {
    & $OmegaCmd @Arguments
    exit $LASTEXITCODE
} catch {
    Write-Error "Failed to execute OMEGA compiler: $_"
    exit 1
}