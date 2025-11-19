param(
    [string]$OmegaProdPath = "$PSScriptRoot\bin\omega-production.exe",
    [string]$LogPath = "$PSScriptRoot\logs\for_range_ext_ci.log"
)

$ErrorActionPreference = "Stop"

Write-Host "Range Transform Extended Tests" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Ensure omega-production exists
if (-not (Test-Path $OmegaProdPath)) {
    Write-Host "❌ omega-production.exe not found at: $OmegaProdPath" -ForegroundColor Red
    exit 1
}

# Prepare output directory
$OutDir = Join-Path $PSScriptRoot "artifacts\range_transform_ext"
if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

# Ensure logs directory
$LogsDir = Split-Path -Path $LogPath -Parent
if ($LogsDir -and -not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

# Create test source with multiple for-range variants
$SourcePath = Join-Path $OutDir "range_transform_ext.omega"
$SourceContent = @"
// Extended range transform test cases
blockchain RangeTransformExt {
    function main() public {
        let sum: u256 = 0;
        // Ascending step 2
        for i in range(0, 10, 2) {
            sum = sum + i;
        }
        // Ascending step 3
        for p in range(0, 9, 3) {
            sum = sum + p;
        }
        // Descending step -3 (signed loop)
        for j in range(10, 0, -3) {
            sum = sum + j;
        }
        // Variable-based bounds (unit step)
        let a: u256 = 5;
        let b: u256 = 5;
        for k in range(a, b) {
            sum = sum + k;
        }
        // Variable-defined step (ascending)
        let step2: u256 = 2;
        for q in range(0, 8, step2) {
            sum = sum + q;
        }
        // Zero-to-zero range (no iterations)
        for m in range(0, 0) {
            sum = sum + m;
        }
        // Large step
        for n in range(0, 100, 20) {
            sum = sum + n;
        }
    }
}
"@
$SourceContent | Out-File -FilePath $SourcePath -Encoding UTF8

Write-Host "Compiling: $SourcePath" -ForegroundColor Yellow

# Compile for EVM (Solidity)
$OutBase = Join-Path $OutDir "range_transform_ext"
# Temporarily relax error action to avoid NativeCommandError when the compiler writes warnings to stderr
$__oldEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$compileOutput = & $OmegaProdPath compile $SourcePath --target evm --output $OutBase 2>&1
# Persist raw compile output to log (append)
try {
    if ($LogPath) {
        "[compile-output] $(Get-Date -Format o)" | Out-File -FilePath $LogPath -Append -Encoding UTF8
        ($compileOutput | Out-String) | Out-File -FilePath $LogPath -Append -Encoding UTF8
    }
} catch {
    Write-Warning "Failed to write compile output to log: $($_.Exception.Message)"
}
$compileExit = $LASTEXITCODE
$ErrorActionPreference = $__oldEAP
if ($compileExit -ne 0) {
    Write-Host "❌ Compilation failed" -ForegroundColor Red
    $compileOutput | Out-String | Write-Host
    try {
        if ($LogPath) {
            "[compile-failed] $(Get-Date -Format o)" | Out-File -FilePath $LogPath -Append -Encoding UTF8
        }
    } catch {}
    exit 1
}

$null = Start-Sleep -Milliseconds 250

$evmMatch = ($compileOutput | Out-String) -match 'EVM output:\s*(.+\.sol)'
if ($evmMatch) {
    $SolPath = $Matches[1].Trim()
} else {
    # Fallback to predictable location: <OutBase>.sol
    $SolPath = "$OutBase.sol"
}

if (-not (Test-Path $SolPath)) {
    Write-Host "❌ Expected Solidity output not found: $SolPath" -ForegroundColor Red
    $compileOutput | Out-String | Write-Host
    exit 1
}

$SolContent = Get-Content $SolPath -Raw

# Scan compile output for known Windows path/quoting noise patterns
$knownNoisePatterns = @(
    'The system cannot find the path specified',
    'CMD\.EXE was started with the above path as the current directory',
    'The input line is too long',
    'A device attached to the system is not functioning',
    'Unhandled Exception:.*System\.ArgumentException:.*path',
    'At line:\s*\d+ char:\s*\d+'
)
$noiseHits = @()
foreach ($pat in $knownNoisePatterns) {
    if ((($compileOutput | Out-String) -match $pat)) {
        $noiseHits += $pat
    }
}
if ($noiseHits.Count -gt 0) {
    Write-Host "⚠️  Detected potential Windows path/quoting noise patterns:" -ForegroundColor Yellow
    $noiseHits | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
    try {
        if ($LogPath) {
            "[noise-detected] $(Get-Date -Format o)" | Out-File -FilePath $LogPath -Append -Encoding UTF8
            ($noiseHits -join "`n") | Out-File -FilePath $LogPath -Append -Encoding UTF8
        }
    } catch {}
}

# Define expected patterns
$patterns = @(
    @{ name = "asc_step2";            regex = 'for \(uint256 i = 0; i < 10; i \+= 2\) \{' },
    @{ name = "asc_step3";            regex = 'for \(uint256 p = 0; p < 9; p \+= 3\) \{' },
    @{ name = "desc_step3_signed";    regex = 'for \(int256 j = 10; j > 0; j -= 3\) \{' },
    @{ name = "var_bounds_unit_step"; regex = 'for \(uint256 k = a; k < b; k \+= 1\) \{' },
    @{ name = "var_step2";            regex = 'for \(uint256 q = 0; q < 8; q \+= step2\) \{' },
    @{ name = "zero_zero";            regex = 'for \(uint256 m = 0; m < 0; m \+= 1\) \{' },
    @{ name = "big_step20";           regex = 'for \(uint256 n = 0; n < 100; n \+= 20\) \{' }
)

$fails = @()
foreach ($p in $patterns) {
    if ($SolContent -match $p.regex) {
        Write-Host "✅ Pattern PASS: $($p.name)" -ForegroundColor Green
    } else {
        Write-Host "❌ Pattern FAIL: $($p.name)" -ForegroundColor Red
        $fails += $p.name
    }
}

if ($fails.Count -gt 0) {
    Write-Host "\nGenerated Solidity ($SolPath):" -ForegroundColor DarkCyan
    Write-Host "--------------------------------" -ForegroundColor DarkCyan
    $SolContent | Out-String | Write-Host
    Write-Host "\nFailed patterns:" -ForegroundColor Yellow
    $fails | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
    exit 1
}

Write-Host "\n🎉 All extended range transform patterns passed." -ForegroundColor Green

# Optional: Solidity syntax check with solc if available
try {
    $solcCmd = Get-Command solc -ErrorAction SilentlyContinue
    if ($solcCmd) {
        Write-Host "Running solc syntax check..." -ForegroundColor Cyan
        $solcOut = & $solcCmd.Source --bin "$SolPath" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ solc reported errors" -ForegroundColor Red
            $solcOut | Out-String | Write-Host
            exit 1
        } else {
            Write-Host "✅ solc syntax check passed" -ForegroundColor Green
        }
    } else {
        Write-Host "Info: solc not found; skipping Solidity syntax check" -ForegroundColor Yellow
    }
} catch {
    Write-Warning "solc check encountered an exception: $($_.Exception.Message)"
}

# Optional: Foundry fallback syntax check (non-blocking)
try {
    $forgeCmd = Get-Command forge -ErrorAction SilentlyContinue
    if ($forgeCmd) {
        Write-Host "Foundry detected; running 'forge fmt --check' on Solidity output..." -ForegroundColor Cyan
        $forgeOut = & $forgeCmd.Source fmt --check "$SolPath" 2>&1
        $forgeExit = $LASTEXITCODE
        if ($LogPath) {
            "[forge-fmt] $(Get-Date -Format o)" | Out-File -FilePath $LogPath -Append -Encoding UTF8
            ($forgeOut | Out-String) | Out-File -FilePath $LogPath -Append -Encoding UTF8
        }
        if ($forgeExit -eq 0) {
            Write-Host "✅ Foundry fmt check passed (file is parseable and formatting OK)" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Foundry fmt reported issues (this may indicate syntax problems or formatting differences)" -ForegroundColor Yellow
            $forgeOut | Out-String | Write-Host
            # Non-blocking: do not fail the test
        }
    } else {
        Write-Host "Info: Foundry (forge) not found; skipping Foundry fallback check" -ForegroundColor Yellow
    }
} catch {
    Write-Warning "Foundry check encountered an exception: $($_.Exception.Message)"
}

exit 0