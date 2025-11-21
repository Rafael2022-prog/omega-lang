param(
  [switch]$Verbose
)

# Minimal runner to invoke Build-ProductionCompiler and surface detailed output
. "$PSScriptRoot\..\build_production_real_native.ps1"

Write-Host "Starting Build-ProductionCompiler (debug runner)" -ForegroundColor Cyan
$result = Build-ProductionCompiler
Write-Host "Result: $result" -ForegroundColor Cyan
if ($result) {
  Write-Host "Build Completed Successfully (debug runner)" -ForegroundColor Green
  exit 0
} else {
  Write-Host "Build Failed (debug runner)" -ForegroundColor Red
  exit 1
}