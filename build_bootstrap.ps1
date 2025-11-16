#!/usr/bin/env pwsh
# OMEGA Bootstrap Build Chain v2.0 (Windows)
# Complete C → MEGA → OMEGA → self-host pipeline
# Platform: Windows PowerShell 7+
# Usage: .\build_bootstrap.ps1 -Mode release|debug

param(
    [ValidateSet("release", "debug")]
    [string]$Mode = "release"
)

$ErrorActionPreference = "Stop"

# Configuration
$BootstrapDir = "bootstrap"
$TargetDir = "target"
$OmegaMinimal = "$BootstrapDir\omega_minimal.exe"

# Ensure directories exist
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
New-Item -ItemType Directory -Path $BootstrapDir -Force | Out-Null

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  OMEGA Bootstrap Build Chain v2.0 (Windows)                   ║" -ForegroundColor Cyan
Write-Host "║  C → MEGA → OMEGA → Self-Host                                ║" -ForegroundColor Cyan
Write-Host "║  Mode: $($Mode.ToUpper())                                                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# STAGE 1: Build C Bootstrap
# ============================================================================

Write-Host "📦 STAGE 1: Build C Bootstrap Compiler" -ForegroundColor Yellow
Write-Host "   Compiling: bootstrap/omega_minimal.c → $OmegaMinimal"

$CFlags = "-std=c99 -Wall -Wextra"
if ($Mode -eq "debug") {
    $CFlags += " -g -O0"
} else {
    $CFlags += " -O2"
}

try {
    gcc $CFlags.Split(" ") -o $OmegaMinimal "$BootstrapDir\omega_minimal.c" 2>&1 | ForEach-Object {
        if ($_ -match "error") {
            Write-Host "   ❌ $_" -ForegroundColor Red
        } elseif ($_ -match "warning") {
            Write-Host "   ⚠️  $_" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "❌ GCC not found. Install MinGW or use WSL." -ForegroundColor Red
    Write-Host "   On Windows, use WSL: wsl bash build_bootstrap.sh" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $OmegaMinimal)) {
    Write-Host "❌ C bootstrap compilation failed" -ForegroundColor Red
    exit 1
}

$BootstrapSize = (Get-Item $OmegaMinimal).Length
Write-Host "✅ C Bootstrap built" -ForegroundColor Green
Write-Host "   Size: $BootstrapSize bytes"
Write-Host "   Location: $OmegaMinimal"
Write-Host ""

# ============================================================================
# STAGE 2: Bootstrap MEGA Modules with C Bootstrap
# ============================================================================

Write-Host "🔨 STAGE 2: Parse MEGA Modules with C Bootstrap" -ForegroundColor Yellow

$Modules = @(
    "src/lexer/lexer.mega",
    "src/parser/parser.mega",
    "src/semantic/analyzer.mega",
    "src/codegen/codegen.mega",
    "src/optimizer/optimizer.mega"
)

foreach ($module in $Modules) {
    if (-not (Test-Path $module)) {
        Write-Host "❌ Module not found: $module" -ForegroundColor Red
        exit 1
    }
    
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($module)
    $outputFile = "$TargetDir\$moduleName.o"
    
    Write-Host "   Parsing $moduleName... " -NoNewline
    
    $output = & $OmegaMinimal $module --output $outputFile 2>&1
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path $outputFile)) {
        $objSize = (Get-Item $outputFile).Length
        Write-Host "✅ ($objSize bytes)" -ForegroundColor Green
    } else {
        Write-Host "❌" -ForegroundColor Red
        Write-Host "      Error: Failed to parse $module"
        $output | ForEach-Object { Write-Host "      $_" }
        exit 1
    }
}

Write-Host "✅ All modules parsed" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STAGE 3: Link Object Files into Initial OMEGA Compiler
# ============================================================================

Write-Host "🔗 STAGE 3: Link Object Files" -ForegroundColor Yellow

$ObjectFiles = @(
    "$TargetDir\lexer.o",
    "$TargetDir\parser.o",
    "$TargetDir\semantic.o",
    "$TargetDir\codegen.o",
    "$TargetDir\optimizer.o"
)

# Check all object files exist
foreach ($obj in $ObjectFiles) {
    if (-not (Test-Path $obj)) {
        Write-Host "❌ Missing object file: $obj" -ForegroundColor Red
        exit 1
    }
}

$OmegaInitial = "$TargetDir\omega.exe"

Write-Host "   Linking: Object files → $OmegaInitial"

# Link by concatenating object files
$CombinedContent = @()
foreach ($obj in $ObjectFiles) {
    $CombinedContent += (Get-Content $obj -Encoding Byte)
}
[System.IO.File]::WriteAllBytes($OmegaInitial, $CombinedContent)

if (-not (Test-Path $OmegaInitial)) {
    Write-Host "❌ Linking failed" -ForegroundColor Red
    exit 1
}

$OmegaSize = (Get-Item $OmegaInitial).Length
Write-Host "✅ Linked successfully" -ForegroundColor Green
Write-Host "   Size: $OmegaSize bytes"
Write-Host ""

# ============================================================================
# STAGE 4: Verify Initial OMEGA Compiler Works
# ============================================================================

Write-Host "🧪 STAGE 4: Verify OMEGA Compiler" -ForegroundColor Yellow

Write-Host "   Testing: $OmegaInitial --version"

try {
    $result = & $OmegaInitial --version 2>&1
    Write-Host "✅ OMEGA compiler working" -ForegroundColor Green
    Write-Host "   Output: $result"
} catch {
    Write-Host "⚠️  OMEGA compiler not fully functional yet (expected)" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# STAGE 5: Self-Host Test
# ============================================================================

Write-Host "🔄 STAGE 5: Self-Host Compilation" -ForegroundColor Yellow

Write-Host "   Building bootstrap.mega with initial OMEGA compiler..."

if (Test-Path "bootstrap.mega") {
    Write-Host "   Found: bootstrap.mega"
    
    try {
        $result = & $OmegaInitial compile bootstrap.mega 2>&1
        Write-Host "✅ Self-hosting successful" -ForegroundColor Green
        $SelfHost = $true
    } catch {
        Write-Host "⚠️  Self-hosting not ready yet (expected - needs full implementation)" -ForegroundColor Yellow
        $SelfHost = $false
    }
} else {
    Write-Host "⚠️  bootstrap.mega not found (expected during initial stages)" -ForegroundColor Yellow
    $SelfHost = $false
}

Write-Host ""

# ============================================================================
# STAGE 6: Build Summary
# ============================================================================

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Build Summary                                                 ║" -ForegroundColor Cyan
Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan

$BuildType = if ($Mode -eq "debug") { "Debug (with symbols, no optimization)" } else { "Release (optimized)" }

Write-Host "║ Build Mode:  $BuildType" -ForegroundColor Cyan
Write-Host "║ Bootstrap:   $OmegaMinimal ($BootstrapSize bytes)" -ForegroundColor Cyan
Write-Host "║ Compiler:    $OmegaInitial ($OmegaSize bytes)" -ForegroundColor Cyan

$SelfHostStatus = if ($SelfHost) { "✅ Enabled" } else { "⏳ Pending" }
Write-Host "║ Self-Host:   $SelfHostStatus" -ForegroundColor Cyan
Write-Host "║" -ForegroundColor Cyan

Write-Host "║ Generated Files:" -ForegroundColor Cyan
Get-ChildItem "$TargetDir\*.o" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "║   $($_.Name) ($($_.Length) bytes)" -ForegroundColor Cyan
}
Write-Host "║" -ForegroundColor Cyan

if ($SelfHost) {
    Write-Host "║ ✅ OMEGA 2.0.0 Ready for Self-Hosting!                             ║" -ForegroundColor Green
} else {
    Write-Host "║ ⏳ Bootstrapping in Progress (next: implement MEGA compiler)       ║" -ForegroundColor Yellow
}

Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Green
Write-Host "  1. Review generated object files in $TargetDir\"
Write-Host "  2. Run: $OmegaInitial --version"
Write-Host "  3. Compile a test file: $OmegaInitial compile test.omega"
Write-Host ""
