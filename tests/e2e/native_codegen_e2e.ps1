param(
  [string]$WinLibsBin = "C:\Users\l3unu\AppData\Local\Programs\WinLibs\mingw64\bin"
)

$ErrorActionPreference = 'Stop'

function Assert-Success {
  param([int]$Code, [string]$Step)
  if ($Code -ne 0) {
    Write-Host "[FAIL] $Step exit code: $Code" -ForegroundColor Red
    exit $Code
  } else {
    Write-Host "[OK] $Step" -ForegroundColor Green
  }
}

function Assert-Exists {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "[FAIL] Missing artifact: $Path" -ForegroundColor Red
    exit 2
  } else {
    Write-Host "[OK] Found artifact: $Path" -ForegroundColor Green
  }
}

Push-Location (Resolve-Path "$PSScriptRoot\..\..\")
try {
  # Ensure runtime DLLs are discoverable
  if (-not $env:Path.Split(';') -contains $WinLibsBin) {
    $env:Path = "$WinLibsBin;" + $env:Path
  }

  $exe = Join-Path (Get-Location) 'bin\omega-production.exe'
  if (-not (Test-Path -LiteralPath $exe)) {
    Write-Host "omega-production.exe not found at $exe" -ForegroundColor Yellow
    Write-Host "Attempting to build..."
    $wrapperRelocated = 'src\wrapper\omega_production_wrapper.cpp'
    $wrapperLegacy = 'build\omega_production_wrapper.cpp'
    $wrapperSource = if (Test-Path -LiteralPath $wrapperRelocated) { $wrapperRelocated } elseif (Test-Path -LiteralPath $wrapperLegacy) { $wrapperLegacy } else { $null }
    if ($null -eq $wrapperSource) {
      Write-Host "Wrapper source not found in src/wrapper or build/." -ForegroundColor Red
      exit 3
    }
    & "$WinLibsBin\g++.exe" -std=c++17 -O2 -Wall -Wextra -o "$exe" $wrapperSource
    Assert-Success $LASTEXITCODE 'Build omega-production.exe'
  }

  # Basic commands
  & $exe version; Assert-Success $LASTEXITCODE 'version'
  & $exe help;    Assert-Success $LASTEXITCODE 'help'

  # Prepare sample
  $sample = 'build\test_contract.omega'
  if (-not (Test-Path -LiteralPath $sample)) {
    Set-Content -LiteralPath $sample -Value '// sample'
  }

  # E2E compile for each target
  & $exe compile $sample --target evm
  Assert-Success $LASTEXITCODE 'compile --target evm'
  Assert-Exists 'build\test_contract.omegair'
  Assert-Exists 'build\test_contract.sol'

  & $exe compile $sample --target solana
  Assert-Success $LASTEXITCODE 'compile --target solana'
  Assert-Exists 'build\test_contract.rs'

  & $exe compile $sample --target cosmos
  Assert-Success $LASTEXITCODE 'compile --target cosmos'
  Assert-Exists 'build\test_contract.go'

  & $exe compile $sample --target all
  Assert-Success $LASTEXITCODE 'compile --target all'
  Assert-Exists 'build\test_contract.sol'
  Assert-Exists 'build\test_contract.rs'
  Assert-Exists 'build\test_contract.go'

  # Build command should process all .omega in repo
  & $exe build
  Assert-Success $LASTEXITCODE 'build'
  & $exe test
  Assert-Success $LASTEXITCODE 'test'

  Write-Host "All E2E tests passed." -ForegroundColor Green
  exit 0
}
finally {
  Pop-Location
}