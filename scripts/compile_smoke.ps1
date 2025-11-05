# Compile Smoke Test Script for OMEGA
# Verifies that new std modules and DeFi/Governance templates compile successfully (compile-only)
param(
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\..\").Path
)

$ErrorActionPreference = 'Stop'

function Find-OmegaCompiler {
    param([string]$Root)
    $exe = Join-Path $Root 'omega.exe'
    $cmd = Join-Path $Root 'omega.cmd'
    $ps1 = Join-Path $Root 'omega.ps1'

    if (Test-Path $ps1) { return @{ kind = 'ps1'; path = $ps1 } }
    if (Test-Path $exe) { return @{ kind = 'exe'; path = $exe } }
    if (Test-Path $cmd) { return @{ kind = 'cmd'; path = $cmd } }
    throw "OMEGA compiler not found (omega.ps1/exe/cmd) in $Root"
}

function Invoke-OmegaCompile {
    param(
        [hashtable]$Compiler,
        [string]$SourcePath,
        [string]$Target = 'native'
    )

    Write-Host "🔧 Compiling: $SourcePath -> target=$Target" -ForegroundColor Cyan
    switch ($Compiler.kind) {
        'exe' { & $Compiler.path compile "$SourcePath" --target $Target }
        'cmd' { & $Compiler.path compile "$SourcePath" --target $Target }
        'ps1' { pwsh -NoProfile -ExecutionPolicy Bypass -File $Compiler.path compile "$SourcePath" --target $Target }
    }
}

# Files to compile (compile-only verification)
$files = @(
    # Std library modules
    'src/std/crypto.mega',
    'src/std/string.mega',
    'src/std/collections.mega',
    # DeFi templates
    'examples/contracts/defi/lending_pool.mega',
    'examples/contracts/defi/amm_swap.mega',
    'examples/contracts/defi/staking_vault.mega',
    # Governance templates
    'examples/contracts/governance/governance_token.mega',
    'examples/contracts/governance/governor.mega',
    'examples/contracts/governance/timelock.mega'
)

$compiler = Find-OmegaCompiler -Root $ProjectRoot
Write-Host "⚙️  Using compiler: $($compiler.kind) at $($compiler.path)" -ForegroundColor Green

# Version banner
try {
    switch ($compiler.kind) {
        'ps1' { pwsh -NoProfile -ExecutionPolicy Bypass -File $compiler.path --version }
        default { & $compiler.path --version }
    }
} catch { Write-Host "[warn] Unable to print compiler version: $($_.Exception.Message)" -ForegroundColor DarkYellow }

$success = @()
$failed  = @()

foreach ($rel in $files) {
    $path = Join-Path $ProjectRoot $rel
    if (-not (Test-Path $path)) {
        Write-Warning "Skipping missing file: $rel"
        continue
    }
    try {
        Invoke-OmegaCompile -Compiler $compiler -SourcePath $path -Target 'native'
        $success += $rel
    } catch {
        Write-Error "Compile failed: $rel - $($_.Exception.Message)"
        $failed += $rel
    }
}

Write-Host ""; Write-Host "📊 Compile Smoke Summary" -ForegroundColor Yellow
Write-Host "✅ Success: $($success.Count)" -ForegroundColor Green
Write-Host "❌ Failed:  $($failed.Count)" -ForegroundColor Red

if ($failed.Count -gt 0) {
    Write-Host "Failed files:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "All compile-only scaffolding verified." -ForegroundColor Green
    exit 0
}