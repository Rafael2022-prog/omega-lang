# OMEGA IDE Plugins - Master Build Script
# This script builds all IDE plugins for OMEGA language support

Write-Host "OMEGA IDE Plugins - Master Build Script"
Write-Host "======================================"
Write-Host ""

# Create master build directory
$MASTER_BUILD_DIR = "build\all-plugins"
New-Item -ItemType Directory -Force -Path $MASTER_BUILD_DIR | Out-Null

Write-Host "Building all OMEGA IDE plugins..."
Write-Host ""

# 1. Build VS Code Extension
Write-Host "1. Building VS Code Extension..."
Set-Location "ide\vscode-extension"
if (Test-Path "package.json") {
    npm install
    npm run package
    if (Test-Path "*.vsix") {
        $VSIX_FILE = Get-ChildItem "*.vsix" | Select-Object -First 1
        Copy-Item $VSIX_FILE.FullName "..\..\$MASTER_BUILD_DIR\$($VSIX_FILE.Name)"
        Write-Host "   ✓ VS Code Extension built: $($VSIX_FILE.Name)"
    } else {
        Write-Host "   ✗ VS Code Extension build failed"
    }
} else {
    Write-Host "   ✗ VS Code Extension source not found"
}
Set-Location "..\.."

# 2. Build Eclipse Plugin
Write-Host "2. Building Eclipse Plugin..."
Set-Location "ide-plugins\eclipse"
if (Test-Path "build_eclipse_plugin.ps1") {
    .\build_eclipse_plugin.ps1
    if (Test-Path "dist\*.jar") {
        $JAR_FILE = Get-ChildItem "dist\*.jar" | Select-Object -First 1
        Copy-Item $JAR_FILE.FullName "..\..\$MASTER_BUILD_DIR\$($JAR_FILE.Name)"
        Write-Host "   ✓ Eclipse Plugin built: $($JAR_FILE.Name)"
    } else {
        Write-Host "   ✗ Eclipse Plugin build failed"
    }
} else {
    Write-Host "   ✗ Eclipse Plugin build script not found"
}
Set-Location "..\.."

# 3. Build IntelliJ Plugin
Write-Host "3. Building IntelliJ Plugin..."
Set-Location "ide-plugins\intellij-idea"
if (Test-Path "build_intellij_plugin.ps1") {
    .\build_intellij_plugin.ps1
    if (Test-Path "dist\*.zip") {
        $ZIP_FILE = Get-ChildItem "dist\*.zip" | Select-Object -First 1
        Copy-Item $ZIP_FILE.FullName "..\..\$MASTER_BUILD_DIR\$($ZIP_FILE.Name)"
        Write-Host "   ✓ IntelliJ Plugin built: $($ZIP_FILE.Name)"
    } else {
        Write-Host "   ✗ IntelliJ Plugin build failed"
    }
} else {
    Write-Host "   ✗ IntelliJ Plugin build script not found"
}
Set-Location "..\.."

# 4. Build Sublime Text Package
Write-Host "4. Building Sublime Text Package..."
Set-Location "ide\sublime-text"
if (Test-Path "*.sublime-package") {
    $PKG_FILE = Get-ChildItem "*.sublime-package" | Select-Object -First 1
    Copy-Item $PKG_FILE.FullName "..\..\$MASTER_BUILD_DIR\$($PKG_FILE.Name)"
    Write-Host "   ✓ Sublime Text Package built: $($PKG_FILE.Name)"
} elseif (Test-Path "*.sublime-syntax") {
    # Create package from syntax files
    $PKG_NAME = "OMEGA-Language-Package.sublime-package"
    Compress-Archive -Path "*.sublime-syntax", "*.tmLanguage", "*.json" -DestinationPath "$MASTER_BUILD_DIR\$PKG_NAME" -Force
    Write-Host "   ✓ Sublime Text Package built: $PKG_NAME"
} else {
    Write-Host "   ✗ Sublime Text Package source not found"
}
Set-Location "..\.."

# Generate build summary
Write-Host ""
Write-Host "Build Summary"
Write-Host "============="
Write-Host ""

$BUILD_FILES = Get-ChildItem "$MASTER_BUILD_DIR\*" -Include "*.vsix","*.jar","*.zip","*.sublime-package"
foreach ($file in $BUILD_FILES) {
    $size = [math]::Round($file.Length / 1KB, 2)
    Write-Host "📦 $($file.Name) - $size KB"
}

Write-Host ""
Write-Host "All plugins built successfully!"
Write-Host "Location: $MASTER_BUILD_DIR"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Test each plugin in respective IDE"
Write-Host "2. Submit to marketplace (see marketplace-guide.md)"
Write-Host "3. Create GitHub release"
Write-Host "4. Update documentation"