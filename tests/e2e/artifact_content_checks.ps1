param(
  [string]$WinLibsBin = "C:\Users\l3unu\AppData\Local\Programs\WinLibs\mingw64\bin"
)

$ErrorActionPreference = 'Stop'

function Assert-Contains {
  param([string]$Path, [string]$Pattern)
  $text = Get-Content -LiteralPath $Path -Raw
  if ($text -notmatch $Pattern) {
    Write-Host "[FAIL] $Path missing '$Pattern'" -ForegroundColor Red
    exit 3
  } else {
    Write-Host "[OK] $Path contains '$Pattern'" -ForegroundColor Green
  }
}

Push-Location (Resolve-Path "$PSScriptRoot\..\..\")
try {
  if (-not $env:Path.Split(';') -contains $WinLibsBin) { $env:Path = "$WinLibsBin;" + $env:Path }
  $exe = Join-Path (Get-Location) 'bin\omega-production.exe'
  if (-not (Test-Path -LiteralPath $exe)) {
    $wrapperRelocated = 'src\wrapper\omega_production_wrapper.cpp'
    $wrapperLegacy = 'build\omega_production_wrapper.cpp'
    $wrapperSource = if (Test-Path -LiteralPath $wrapperRelocated) { $wrapperRelocated } elseif (Test-Path -LiteralPath $wrapperLegacy) { $wrapperLegacy } else { $null }
    if ($null -eq $wrapperSource) {
      Write-Host "[FAIL] Wrapper source not found in src/wrapper or build/." -ForegroundColor Red
      exit 3
    }
    & "$WinLibsBin\g++.exe" -std=c++17 -O2 -Wall -Wextra -o "$exe" $wrapperSource
    if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] build" -ForegroundColor Red; exit $LASTEXITCODE }
  }

  # Compile test_contract (EVM) and validate content
  & $exe compile 'build\test_contract.omega' --target evm
  if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] compile test_contract" -ForegroundColor Red; exit $LASTEXITCODE }
  Assert-Contains 'build\test_contract.sol' 'contract\s+TestContract'
  Assert-Contains 'build\test_contract.sol' 'function\s+transfer\('
  Assert-Contains 'build\test_contract.sol' 'mapping\(address\s*=>\s*uint256\)\s*balances'

  # Compile BasicToken (EVM) and validate events
  & $exe compile 'tests\test_contracts\BasicToken.omega' --target evm --output 'tests\test_contracts'
  if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] compile BasicToken (evm)" -ForegroundColor Red; exit $LASTEXITCODE }
  Assert-Contains 'tests\test_contracts\BasicToken.sol' 'contract\s+BasicToken'
  Assert-Contains 'tests\test_contracts\BasicToken.sol' 'event\s+Transfer\('
  Assert-Contains 'tests\test_contracts\BasicToken.sol' 'event\s+Approval\('

  # Solana & Cosmos content checks for BasicToken
  & $exe compile 'tests\test_contracts\BasicToken.omega' --target solana --output 'tests\test_contracts'
  if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] compile BasicToken (solana)" -ForegroundColor Red; exit $LASTEXITCODE }
  Assert-Contains 'tests\test_contracts\BasicToken.rs' 'pub\s+mod\s+BasicToken'

  & $exe compile 'tests\test_contracts\BasicToken.omega' --target cosmos --output 'tests\test_contracts'
  if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] compile BasicToken (cosmos)" -ForegroundColor Red; exit $LASTEXITCODE }
  Assert-Contains 'tests\test_contracts\BasicToken.go' 'package\s+BasicToken'

  Write-Host "Artifact content checks passed." -ForegroundColor Green
  exit 0
}
finally {
  Pop-Location
}