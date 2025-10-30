# OMEGA Installation Script
# This script installs OMEGA compiler and sets up file associations for .mega files

param(
    [Parameter(Mandatory=$false)]
    [string]$InstallPath = "$env:ProgramFiles\OMEGA",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipFileAssociation = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipVSCodeExtension = $false
)

Write-Host "🚀 Installing OMEGA Blockchain Compiler..." -ForegroundColor Cyan
Write-Host "Installation Path: $InstallPath" -ForegroundColor Yellow

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script requires administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

# Create installation directory
Write-Host "📁 Creating installation directory..." -ForegroundColor Green
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

# Copy OMEGA executable
Write-Host "📦 Installing OMEGA executable..." -ForegroundColor Green
$omegaExe = Join-Path $PSScriptRoot "..\target\release\omega.exe"
if (Test-Path $omegaExe) {
    Copy-Item $omegaExe -Destination "$InstallPath\omega.exe" -Force
} else {
    Write-Host "❌ OMEGA executable not found at $omegaExe" -ForegroundColor Red
    Write-Host "Please build OMEGA first using: cargo build --release" -ForegroundColor Yellow
    exit 1
}

# Copy OMEGA icon
Write-Host "🎨 Installing OMEGA icon..." -ForegroundColor Green
$iconSource = Join-Path $PSScriptRoot "..\LOGO-OMEGA.png"
if (Test-Path $iconSource) {
    # Convert PNG to ICO (simplified - in real scenario, use proper conversion)
    Copy-Item $iconSource -Destination "$InstallPath\omega-icon.png" -Force
    
    # Create a simple ICO file reference (in production, convert PNG to ICO)
    $icoPath = "$InstallPath\omega-icon.ico"
    Copy-Item $iconSource -Destination $icoPath -Force
}

# Add to PATH
Write-Host "🔧 Adding OMEGA to system PATH..." -ForegroundColor Green
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($currentPath -notlike "*$InstallPath*") {
    $newPath = "$currentPath;$InstallPath"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
    Write-Host "✅ Added $InstallPath to system PATH" -ForegroundColor Green
} else {
    Write-Host "ℹ️ OMEGA is already in system PATH" -ForegroundColor Yellow
}

# Set up file associations
if (-not $SkipFileAssociation) {
    Write-Host "📄 Setting up .mega file associations..." -ForegroundColor Green
    
    # Import registry settings
    $regFile = Join-Path $PSScriptRoot "windows\omega-file-association.reg"
    if (Test-Path $regFile) {
        try {
            Start-Process "regedit.exe" -ArgumentList "/s", "`"$regFile`"" -Wait -NoNewWindow
            Write-Host "✅ File associations configured successfully" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Failed to configure file associations: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Refresh shell associations
    try {
        Add-Type -AssemblyName Microsoft.VisualBasic
        [Microsoft.VisualBasic.Interaction]::Shell("ie4uinit.exe -show", 0, $true)
    } catch {
        Write-Host "ℹ️ Please restart Windows Explorer to see file association changes" -ForegroundColor Yellow
    }
}

# Install VS Code extension
if (-not $SkipVSCodeExtension) {
    Write-Host "🔌 Installing VS Code extension..." -ForegroundColor Green
    
    $vscodePath = Get-Command "code" -ErrorAction SilentlyContinue
    if ($vscodePath) {
        $extensionPath = Join-Path $PSScriptRoot "..\omega-vscode-extension"
        if (Test-Path $extensionPath) {
            try {
                & code --install-extension $extensionPath --force
                Write-Host "✅ VS Code extension installed successfully" -ForegroundColor Green
            } catch {
                Write-Host "⚠️ Failed to install VS Code extension: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "ℹ️ VS Code not found. Skipping extension installation." -ForegroundColor Yellow
    }
}

# Create desktop shortcut
Write-Host "🖥️ Creating desktop shortcut..." -ForegroundColor Green
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "OMEGA Compiler.lnk"

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-NoExit -Command `"cd ~; omega --help`""
$Shortcut.WorkingDirectory = "$env:USERPROFILE"
$Shortcut.IconLocation = "$InstallPath\omega-icon.ico"
$Shortcut.Description = "OMEGA Blockchain Compiler"
$Shortcut.Save()

# Create start menu entry
Write-Host "📋 Creating start menu entry..." -ForegroundColor Green
$startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
$omegaStartMenu = Join-Path $startMenuPath "OMEGA"
if (!(Test-Path $omegaStartMenu)) {
    New-Item -ItemType Directory -Path $omegaStartMenu -Force | Out-Null
}

$startMenuShortcut = Join-Path $omegaStartMenu "OMEGA Compiler.lnk"
$StartShortcut = $WshShell.CreateShortcut($startMenuShortcut)
$StartShortcut.TargetPath = "powershell.exe"
$StartShortcut.Arguments = "-NoExit -Command `"cd ~; omega --help`""
$StartShortcut.WorkingDirectory = "$env:USERPROFILE"
$StartShortcut.IconLocation = "$InstallPath\omega-icon.ico"
$StartShortcut.Description = "OMEGA Blockchain Compiler"
$StartShortcut.Save()

# Verify installation
Write-Host "🔍 Verifying installation..." -ForegroundColor Green
try {
    $version = & "$InstallPath\omega.exe" --version 2>&1
    Write-Host "✅ OMEGA installed successfully!" -ForegroundColor Green
    Write-Host "Version: $version" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Installation verification failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 OMEGA Installation Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Restart your terminal or VS Code" -ForegroundColor White
Write-Host "2. Create a new project: omega init my-project" -ForegroundColor White
Write-Host "3. Open .mega files with syntax highlighting" -ForegroundColor White
Write-Host ""
Write-Host "Documentation: https://omega-lang.org/docs" -ForegroundColor Blue
Write-Host "Support: https://github.com/Rafael2022-prog/omega-lang/issues" -ForegroundColor Blue