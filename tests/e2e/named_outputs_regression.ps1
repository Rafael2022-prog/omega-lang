param(
  [string]$WinLibsBin = "C:\Users\l3unu\AppData\Local\Programs\WinLibs\mingw64\bin",
  [switch]$ForceRebuild
)

$ErrorActionPreference = 'Stop'

function Assert-Success {
  param([int]$Code, [string]$Step)
  if ($Code -ne 0) { Write-Host "[FAIL] $Step exit code: $Code" -ForegroundColor Red; exit $Code } else { Write-Host "[OK] $Step" -ForegroundColor Green }
}

Push-Location (Resolve-Path "$PSScriptRoot\..\..\")
try {
  if (-not $env:Path.Split(';') -contains $WinLibsBin) { $env:Path = "$WinLibsBin;" + $env:Path }

  $exe = Join-Path (Get-Location) 'bin\omega-production.exe'
  $needsRebuild = $ForceRebuild.IsPresent -or -not (Test-Path -LiteralPath $exe)
  if (-not $needsRebuild) {
    # Detect batch/python-based stub or older wrapper by inspecting version output
    $verOut = & $exe version 2>&1
    $isCppWrapper = ($verOut -match 'OMEGA Production Wrapper' -or $verOut -match 'OMEGA Compiler v')
    if (-not $isCppWrapper) {
      Write-Host "Existing omega-production.exe is not the C++ wrapper; rebuilding from src/wrapper..." -ForegroundColor Yellow
      $needsRebuild = $true
    }
  }
  if ($needsRebuild) {
    Write-Host "Building omega-production.exe (C++ wrapper) ..." -ForegroundColor Yellow
    $wrapperRelocated = 'src\wrapper\omega_production_wrapper.cpp'
    $wrapperLegacy = 'build\omega_production_wrapper.cpp'
    $wrapperSource = if (Test-Path -LiteralPath $wrapperRelocated) { $wrapperRelocated } elseif (Test-Path -LiteralPath $wrapperLegacy) { $wrapperLegacy } else { $null }
    if ($null -eq $wrapperSource) { Write-Host "Wrapper source not found in src/wrapper or build/." -ForegroundColor Red; exit 3 }
    & "$WinLibsBin\g++.exe" -std=c++17 -O2 -Wall -Wextra -municode -o "$exe" $wrapperSource
    if ($LASTEXITCODE -ne 0) {
      if (Test-Path -LiteralPath $exe) {
        Write-Host "Build failed; using existing omega-production.exe" -ForegroundColor Yellow
      } else {
        Write-Host "Build failed and no existing omega-production.exe; aborting" -ForegroundColor Red
        exit $LASTEXITCODE
      }
    } else {
      Write-Host "[OK] Build omega-production.exe" -ForegroundColor Green
    }
  }

  $input = 'tests\test_contracts\NamedOutputsExample.omega'
  if (-not (Test-Path -LiteralPath $input)) { Write-Host "[FAIL] Missing test input: $input" -ForegroundColor Red; exit 2 }

  Write-Host "Running compile for NamedOutputsExample (EVM)"
  $native = Join-Path (Get-Location) 'omega.exe'
  & $native compile $input --target evm --output 'tests\test_contracts'
  $code = $LASTEXITCODE
  if ($code -ne 0) {
    Write-Host "[INFO] Compile failed (exit=$code). Checking for diagnostic patterns..." -ForegroundColor Yellow
    # Look for typical crash indicators
    $patterns = @(
      '\[FATAL\]\s*std::terminate',
      'std::out_of_range',
      'Unhandled exception',
      'Index out of range',
      'CreateProcessW failed'
    )
    foreach ($p in $patterns) {
      Write-Host " - Pattern: $p"
    }
    exit $code
  }

  # Validate generated outputs exist
  $sol = 'tests\test_contracts\NamedOutputsExample.sol'
  $rs  = 'tests\test_contracts\NamedOutputsExample.rs'
  $go  = 'tests\test_contracts\NamedOutputsExample.go'

  if (-not (Test-Path -LiteralPath $sol)) { Write-Host "[FAIL] Missing artifact: $sol" -ForegroundColor Red; exit 4 } else { Write-Host "[OK] Found artifact: $sol" -ForegroundColor Green }
  if (Test-Path -LiteralPath $rs) { Write-Host "[OK] Found artifact: $rs" -ForegroundColor Green } else { Write-Host "[INFO] No Rust artifact found (non-fatal)" -ForegroundColor Yellow }
  if (Test-Path -LiteralPath $go) { Write-Host "[OK] Found artifact: $go" -ForegroundColor Green } else { Write-Host "[INFO] No Go artifact found (non-fatal)" -ForegroundColor Yellow }

  Write-Host "NamedOutputs regression test completed." -ForegroundColor Green
  exit 0
}
finally {
  Pop-Location
}