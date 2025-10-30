# OMEGA Native Build Script
# PowerShell build system untuk OMEGA self-hosting compiler
# Menggantikan cargo build dengan sistem build native OMEGA

param(
    [string]$Target = "native",
    [string]$Mode = "debug", 
    [switch]$Clean,
    [switch]$Test,
    [switch]$Docs,
    [switch]$Install,
    [switch]$Package,
    [switch]$Verbose,
    [switch]$Help
)

# Project configuration
$ProjectName = "omega"
$Version = "1.0.0"
$MainFile = "src\main.mega"
$ConfigFile = "omega-build.toml"
$TargetDir = "target"
$BuildDir = "build"

# Colors for output
$ColorReset = "`e[0m"
$ColorRed = "`e[31m"
$ColorGreen = "`e[32m"
$ColorYellow = "`e[33m"
$ColorBlue = "`e[34m"
$ColorMagenta = "`e[35m"
$ColorCyan = "`e[36m"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = $ColorReset)
    Write-Host "$Color$Message$ColorReset"
}

function Show-Help {
    Write-ColorOutput "OMEGA Native Build System" $ColorCyan
    Write-ColorOutput "=========================" $ColorCyan
    Write-Host ""
    Write-ColorOutput "Usage: .\build.ps1 [OPTIONS]" $ColorYellow
    Write-Host ""
    Write-ColorOutput "Options:" $ColorBlue
    Write-Host "  -Target <target>    Build target (native, wasm, evm-bytecode, solana-bpf)"
    Write-Host "  -Mode <mode>        Build mode (debug, release)"
    Write-Host "  -Clean              Clean build artifacts before building"
    Write-Host "  -Test               Run tests after building"
    Write-Host "  -Docs               Generate documentation"
    Write-Host "  -Install            Install compiler system-wide"
    Write-Host "  -Package            Create distribution package"
    Write-Host "  -Verbose            Enable verbose output"
    Write-Host "  -Help               Show this help message"
    Write-Host ""
    Write-ColorOutput "Examples:" $ColorGreen
    Write-Host "  .\build.ps1                          # Debug build"
    Write-Host "  .\build.ps1 -Mode release            # Release build"
    Write-Host "  .\build.ps1 -Clean -Mode release     # Clean release build"
    Write-Host "  .\build.ps1 -Test                    # Build and test"
    Write-Host "  .\build.ps1 -Target wasm             # Build for WebAssembly"
    Write-Host ""
}

function Test-OmegaCompiler {
    # Check if OMEGA compiler is available
    try {
        $result = & omega --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

function Invoke-Bootstrap {
    Write-ColorOutput "🌱 Bootstrap Mode: No OMEGA compiler found" $ColorYellow
    Write-ColorOutput "📥 Please install OMEGA bootstrap compiler first:" $ColorYellow
    Write-Host "   1. Download from: https://github.com/omega-lang/omega/releases"
    Write-Host "   2. Or build from source using existing compiler"
    Write-Host "   3. Add to PATH and retry"
    exit 1
}

function Clean-BuildArtifacts {
    Write-ColorOutput "🧹 Cleaning build artifacts..." $ColorYellow
    
    if (Test-Path $TargetDir) {
        Remove-Item -Recurse -Force $TargetDir
        Write-ColorOutput "   ✅ Removed $TargetDir" $ColorGreen
    }
    
    if (Test-Path $BuildDir) {
        Remove-Item -Recurse -Force $BuildDir  
        Write-ColorOutput "   ✅ Removed $BuildDir" $ColorGreen
    }
    
    if (Test-Path ".omega\cache") {
        Remove-Item -Recurse -Force ".omega\cache"
        Write-ColorOutput "   ✅ Removed .omega\cache" $ColorGreen
    }
    
    Write-ColorOutput "✅ Clean completed!" $ColorGreen
}

function Build-Omega {
    param([string]$BuildMode, [string]$BuildTarget)
    
    Write-ColorOutput "🔨 Building OMEGA Self-Hosting Compiler..." $ColorCyan
    Write-ColorOutput "📦 Project: $ProjectName v$Version" $ColorBlue
    Write-ColorOutput "🎯 Target: $BuildTarget" $ColorBlue  
    Write-ColorOutput "🔧 Mode: $BuildMode" $ColorBlue
    Write-Host ""
    
    # Create target directories
    if (!(Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir | Out-Null
    }
    if (!(Test-Path $BuildDir)) {
        New-Item -ItemType Directory -Path $BuildDir | Out-Null
    }
    
    # Check for OMEGA compiler
    if (!(Test-OmegaCompiler)) {
        Invoke-Bootstrap
        return $false
    }
    
    # Build command construction
    $buildArgs = @("build")
    $buildArgs += "--config", $ConfigFile
    $buildArgs += "--target", $BuildTarget
    
    if ($BuildMode -eq "release") {
        $buildArgs += "--release"
        $buildArgs += "--optimize"
    } else {
        $buildArgs += "--debug"
    }
    
    if ($Verbose) {
        $buildArgs += "--verbose"
    }
    
    # Output file
    $outputName = if ($BuildTarget -eq "native") { 
        if ($IsWindows) { "omega.exe" } else { "omega" }
    } elseif ($BuildTarget -eq "wasm") {
        "omega.wasm"
    } elseif ($BuildTarget -eq "evm-bytecode") {
        "omega.evm"
    } elseif ($BuildTarget -eq "solana-bpf") {
        "omega.so"
    } else {
        "omega"
    }
    
    $buildArgs += "--output", "$TargetDir\$outputName"
    
    Write-ColorOutput "⚙️ Executing OMEGA native build..." $ColorYellow
    if ($Verbose) {
        Write-ColorOutput "Command: omega $($buildArgs -join ' ')" $ColorMagenta
    }
    
    # Execute build
    try {
        & omega @buildArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-ColorOutput "✅ Build completed successfully!" $ColorGreen
            Write-ColorOutput "📍 Output: $TargetDir\$outputName" $ColorGreen
            
            # Show file size
            if (Test-Path "$TargetDir\$outputName") {
                $fileSize = (Get-Item "$TargetDir\$outputName").Length
                $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
                Write-ColorOutput "📏 Size: $fileSizeMB MB" $ColorBlue
            }
            
            return $true
        } else {
            Write-ColorOutput "❌ Build failed with exit code $LASTEXITCODE" $ColorRed
            return $false
        }
    } catch {
        Write-ColorOutput "❌ Build failed: $($_.Exception.Message)" $ColorRed
        return $false
    }
}

function Run-Tests {
    Write-ColorOutput "🧪 Running OMEGA tests..." $ColorCyan
    
    try {
        & omega test --config $ConfigFile
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Tests completed successfully!" $ColorGreen
            return $true
        } else {
            Write-ColorOutput "❌ Tests failed with exit code $LASTEXITCODE" $ColorRed
            return $false
        }
    } catch {
        Write-ColorOutput "❌ Tests failed: $($_.Exception.Message)" $ColorRed
        return $false
    }
}

function Generate-Docs {
    Write-ColorOutput "📚 Generating documentation..." $ColorCyan
    
    try {
        & omega docs --config $ConfigFile --output "docs\generated"
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Documentation generated!" $ColorGreen
            return $true
        } else {
            Write-ColorOutput "❌ Documentation generation failed" $ColorRed
            return $false
        }
    } catch {
        Write-ColorOutput "❌ Documentation generation failed: $($_.Exception.Message)" $ColorRed
        return $false
    }
}

function Install-Omega {
    Write-ColorOutput "📦 Installing OMEGA compiler..." $ColorCyan
    
    $installPath = "C:\Program Files\OMEGA\bin"
    $executableName = "omega.exe"
    $sourcePath = "$TargetDir\$executableName"
    
    if (!(Test-Path $sourcePath)) {
        Write-ColorOutput "❌ Executable not found: $sourcePath" $ColorRed
        Write-ColorOutput "   Please build first: .\build.ps1 -Mode release" $ColorYellow
        return $false
    }
    
    try {
        # Create installation directory
        if (!(Test-Path $installPath)) {
            New-Item -ItemType Directory -Path $installPath -Force | Out-Null
        }
        
        # Copy executable
        Copy-Item $sourcePath "$installPath\$executableName" -Force
        
        Write-ColorOutput "✅ OMEGA installed to $installPath" $ColorGreen
        Write-ColorOutput "📝 Add $installPath to your PATH environment variable" $ColorYellow
        return $true
    } catch {
        Write-ColorOutput "❌ Installation failed: $($_.Exception.Message)" $ColorRed
        Write-ColorOutput "   Try running as Administrator" $ColorYellow
        return $false
    }
}

function Create-Package {
    Write-ColorOutput "📦 Creating distribution package..." $ColorCyan
    
    $distDir = "dist"
    $packageName = "$ProjectName-$Version-windows"
    $packageDir = "$distDir\$packageName"
    
    try {
        # Create package directory
        if (Test-Path $distDir) {
            Remove-Item -Recurse -Force $distDir
        }
        New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
        
        # Copy files
        Copy-Item "$TargetDir\omega.exe" "$packageDir\" -ErrorAction Stop
        Copy-Item "README.md" "$packageDir\" -ErrorAction Stop
        Copy-Item "LICENSE" "$packageDir\" -ErrorAction Stop
        
        if (Test-Path "docs") {
            Copy-Item "docs" "$packageDir\" -Recurse -ErrorAction Stop
        }
        
        # Create archive
        $archivePath = "$distDir\$packageName.zip"
        Compress-Archive -Path "$packageDir\*" -DestinationPath $archivePath -Force
        
        Write-ColorOutput "✅ Distribution package created: $archivePath" $ColorGreen
        return $true
    } catch {
        Write-ColorOutput "❌ Package creation failed: $($_.Exception.Message)" $ColorRed
        return $false
    }
}

function Show-Status {
    Write-ColorOutput "📊 OMEGA Project Status" $ColorCyan
    Write-ColorOutput "=======================" $ColorCyan
    Write-Host ""
    Write-ColorOutput "Project: $ProjectName v$Version" $ColorBlue
    Write-ColorOutput "Main file: $MainFile" $ColorBlue
    Write-ColorOutput "Config: $ConfigFile" $ColorBlue
    Write-Host ""
    
    # Check compiler availability
    if (Test-OmegaCompiler) {
        Write-ColorOutput "✅ OMEGA compiler available" $ColorGreen
        try {
            $version = & omega --version 2>$null
            Write-ColorOutput "   Version: $version" $ColorBlue
        } catch {}
    } else {
        Write-ColorOutput "❌ OMEGA compiler not found" $ColorRed
    }
    
    # Check build artifacts
    Write-Host ""
    Write-ColorOutput "🔧 Build artifacts:" $ColorBlue
    if (Test-Path "$TargetDir\omega.exe") {
        $fileSize = (Get-Item "$TargetDir\omega.exe").Length
        $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
        Write-ColorOutput "   ✅ omega.exe ($fileSizeMB MB)" $ColorGreen
    } else {
        Write-ColorOutput "   ❌ omega.exe not found" $ColorRed
    }
    
    # Check source files
    $megaFiles = (Get-ChildItem -Path "src" -Filter "*.mega" -Recurse).Count
    Write-ColorOutput "   📁 MEGA files: $megaFiles" $ColorBlue
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-ColorOutput "OMEGA Native Build System v$Version" $ColorCyan
Write-Host ""

# Clean if requested
if ($Clean) {
    Clean-BuildArtifacts
    Write-Host ""
}

# Build
$buildSuccess = Build-Omega -BuildMode $Mode -BuildTarget $Target

if (!$buildSuccess) {
    exit 1
}

# Run tests if requested
if ($Test -and $buildSuccess) {
    Write-Host ""
    $testSuccess = Run-Tests
    if (!$testSuccess) {
        exit 1
    }
}

# Generate docs if requested
if ($Docs -and $buildSuccess) {
    Write-Host ""
    Generate-Docs | Out-Null
}

# Install if requested
if ($Install -and $buildSuccess) {
    Write-Host ""
    Install-Omega | Out-Null
}

# Package if requested  
if ($Package -and $buildSuccess) {
    Write-Host ""
    Create-Package | Out-Null
}

Write-Host ""
Show-Status
Write-Host ""
Write-ColorOutput "🎉 Build process completed!" $ColorGreen