# 🚀 OMEGA IDE Plugin Publisher Script (PowerShell Version)
# This script helps publish all OMEGA IDE plugins to their respective marketplaces

Write-Host "Starting OMEGA IDE Plugin Publishing Process..." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Function to print colored output
function Write-Info {
    param($Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if all plugins are built
Write-Info "Verifying plugin builds..."

$PLUGINS_BUILT = $true

# Check VS Code extension
if (Test-Path "build\omega-language-support-1.0.0.vsix") {
    Write-Info "VS Code extension built"
} elseif (Test-Path "..\ide\vscode-extension\omega-language-support-1.0.0.vsix") {
    Write-Info "VS Code extension built"
    Copy-Item "..\ide\vscode-extension\omega-language-support-1.0.0.vsix" "build\" -Force
} else {
    Write-Warning "VS Code extension not found. Run build script first."
    $PLUGINS_BUILT = $false
}

# Check Eclipse plugin
if (Test-Path "build\com.omega.lang.eclipse_1.0.0.jar") {
    Write-Info "Eclipse plugin built"
} elseif (Test-Path "eclipse\plugins\com.omega.lang.eclipse_1.0.0.jar") {
    Write-Info "Eclipse plugin built"
    Copy-Item "eclipse\plugins\com.omega.lang.eclipse_1.0.0.jar" "build\" -Force
} else {
    Write-Warning "Eclipse plugin not found. Run build script first."
    $PLUGINS_BUILT = $false
}

# Check IntelliJ plugin
if (Test-Path "build\OMEGA-IntelliJ-Plugin-1.0.0.zip") {
    Write-Info "IntelliJ plugin built"
} elseif (Test-Path "intellij-idea\build\distributions\OMEGA-IntelliJ-Plugin-1.0.0.zip") {
    Write-Info "IntelliJ plugin built"
    Copy-Item "intellij-idea\build\distributions\OMEGA-IntelliJ-Plugin-1.0.0.zip" "build\" -Force
} else {
    Write-Warning "IntelliJ plugin not found. Run build script first."
    $PLUGINS_BUILT = $false
}

# Check Sublime Text package
if (Test-Path "build\OMEGA.sublime-package") {
    Write-Info "Sublime Text package built"
} elseif (Test-Path "sublime-text\build\OMEGA.sublime-package") {
    Write-Info "Sublime Text package built"
    Copy-Item "sublime-text\build\OMEGA.sublime-package" "build\" -Force
} else {
    Write-Warning "Sublime Text package not found. Run build script first."
    $PLUGINS_BUILT = $false
}

if (-not $PLUGINS_BUILT) {
    Write-Error "Some plugins are not built. Please run build_all_plugins.ps1 first."
    exit 1
}

Write-Info "All plugins verified! Starting publishing process..."

# VS Code Marketplace Publishing
Write-Host "`nVS Code Extension Publishing Steps:" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "1. Go to https://marketplace.visualstudio.com/manage"
Write-Host "2. Click 'Publish Extensions'"
Write-Host "3. Upload the .vsix file: ..\ide\vscode-extension\omega-language-support-1.0.0.vsix"
Write-Host "4. Fill in the metadata:"
Write-Host "   - Display Name: OMEGA Language Support"
Write-Host "   - Description: Syntax highlighting for OMEGA blockchain language"
Write-Host "   - Categories: Programming Languages, Blockchain"
Write-Host "   - Keywords: omega, blockchain, smart-contracts"
Write-Host "5. Submit for review"
Write-Host ""
Write-Host "Package location: build\omega-language-support-1.0.0.vsix"
Write-Host ""

# Eclipse Marketplace Publishing
Write-Host "Eclipse Plugin Publishing Steps:" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "1. Go to https://marketplace.eclipse.org"
Write-Host "2. Click 'Add Content' -> 'Create New Listing'"
Write-Host "3. Upload the JAR file: eclipse\plugins\com.omega.lang.eclipse_1.0.0.jar"
Write-Host "4. Fill plugin information"
Write-Host "5. Submit for review"
Write-Host ""
Write-Host "Package location: build\com.omega.lang.eclipse_1.0.0.jar"
Write-Host ""

# IntelliJ Marketplace Publishing
Write-Host "IntelliJ Plugin Publishing Steps:" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "1. Go to https://plugins.jetbrains.com"
Write-Host "2. Click 'Upload Plugin'"
Write-Host "3. Upload the ZIP file: intellij-idea\build\distributions\OMEGA-IntelliJ-Plugin-1.0.0.zip"
Write-Host "4. Fill plugin information"
Write-Host "5. Submit for review"
Write-Host ""
Write-Host "Package location: build\OMEGA-IntelliJ-Plugin-1.0.0.zip"
Write-Host ""

# Sublime Text Package Control Publishing
Write-Host "Sublime Text Publishing Steps:" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "1. Create GitHub release with tag: v1.0.0-ide-plugins"
Write-Host "2. Upload: sublime-text\build\OMEGA.sublime-package"
Write-Host "3. Fork https://github.com/wbond/package_control_channel"
Write-Host "4. Submit PR with package info"
Write-Host ""
Write-Host "Package location: build\OMEGA.sublime-package"
Write-Host ""

# Create release notes
Write-Host "Creating Release Notes..." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

$releaseNotes = @"
# OMEGA IDE Plugins v1.0.0 - Release Notes

## What's New

### VS Code Extension
- Syntax highlighting for .mega and .omega files
- Language configuration and snippets
- File icon association
- Code completion support

### Eclipse Plugin
- Syntax highlighting with custom rules
- File association and icon support
- Editor configuration
- Plugin architecture ready

### IntelliJ Plugin
- Language definition and syntax highlighting
- File type association
- Custom icons and themes
- Build system integration

### Sublime Text Package
- Syntax definition with sublime-syntax
- File type configuration
- Custom icons and themes
- Package Control ready

## Installation

### VS Code
1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for "OMEGA Language Support"
4. Click Install

### Eclipse
1. Open Eclipse
2. Go to Help → Eclipse Marketplace
3. Search for "OMEGA Language Support"
4. Click Install

### IntelliJ IDEA
1. Open IntelliJ IDEA
2. Go to File → Settings → Plugins
3. Search for "OMEGA Language Support"
4. Click Install

### Sublime Text
1. Open Sublime Text
2. Open Command Palette (Ctrl+Shift+P)
3. Type "Package Control: Install Package"
4. Search for "OMEGA Language Support"
5. Click Install

## Requirements

- VS Code: Version 1.60.0 or higher
- Eclipse: Version 2020-06 or higher
- IntelliJ IDEA: Version 2020.1 or higher
- Sublime Text: Version 3.0 or higher

## Support

For support and feedback:
- GitHub Issues: https://github.com/omega-lang/omega/issues
- Discord: https://discord.gg/omega-lang
- Email: support@omegalang.xyz

Thank you for using OMEGA IDE Plugins!
"@

$releaseNotes | Out-File -FilePath "RELEASE_NOTES.md" -Encoding UTF8
Write-Info "Release notes created: RELEASE_NOTES.md"

# Final summary
Write-Host "`nPublishing Process Ready!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "Summary of packages ready for submission:"
Write-Host ""
Write-Host "VS Code: ..\ide\vscode-extension\omega-language-support-1.0.0.vsix"
Write-Host "Eclipse: eclipse\plugins\com.omega.lang.eclipse_1.0.0.jar"
Write-Host "IntelliJ: intellij-idea\build\distributions\OMEGA-IntelliJ-Plugin-1.0.0.zip"
Write-Host "Sublime Text: sublime-text\build\OMEGA.sublime-package"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Visit each marketplace website"
Write-Host "2. Upload the respective package files"
Write-Host "3. Fill in the required information"
Write-Host "4. Submit for review"
Write-Host ""
Write-Host "For support: support@omegalang.xyz"
Write-Host "Documentation: https://docs.omegalang.xyz"
Write-Host ""
Write-Info "OMEGA IDE Plugins are ready for publication!"

Write-Host "`nPress Enter to exit..."
Read-Host