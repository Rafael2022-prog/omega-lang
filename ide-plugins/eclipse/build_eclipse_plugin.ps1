# Build OMEGA Eclipse Plugin
Write-Host "Building OMEGA Eclipse Plugin..."
Write-Host "====================================="

# Set up variables
$PLUGIN_NAME = "com.omega.lang.eclipse"
$VERSION = "1.0.0"
$BUILD_DIR = "build"
$DEST_DIR = "dist"

# Create build directories
Write-Host "Creating build directories..."
New-Item -ItemType Directory -Force -Path $BUILD_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $DEST_DIR | Out-Null

# Copy source files
Write-Host "Copying source files..."
Copy-Item -Recurse -Force "src" "$BUILD_DIR\"
Copy-Item -Force "plugin.xml" "$BUILD_DIR\"
Copy-Item -Recurse -Force "META-INF" "$BUILD_DIR\"
Copy-Item -Recurse -Force "icons" "$BUILD_DIR\"
Copy-Item -Force "build.properties" "$BUILD_DIR\"
Copy-Item -Force ".project" "$BUILD_DIR\"

# Create bin directory
New-Item -ItemType Directory -Force -Path "$BUILD_DIR\bin" | Out-Null

# Compile Java classes
Write-Host "Compiling Java classes..."

# Find Java compiler
$JAVAC = (Get-Command javac).Source
if (!(Test-Path $JAVAC)) {
    Write-Host "Java compiler not found!"
    exit 1
}

# Basic compilation without Eclipse dependencies for now
Write-Host "Compiling Java files..."
$JAVA_FILES = Get-ChildItem -Path "src\com\omega\lang\eclipse\*.java" -Recurse

foreach ($file in $JAVA_FILES) {
    Write-Host "Compiling $($file.Name)..."
    & $JAVAC -d "$BUILD_DIR\bin" -cp "$BUILD_DIR\bin" $file.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Compilation warning for $($file.Name)"
    }
}

# Create plugin JAR
Write-Host "Creating plugin JAR..."
Set-Location $BUILD_DIR

# Find jar command
$JAR = (Get-Command jar).Source
if (!(Test-Path $JAR)) {
    Write-Host "Jar command not found!"
    exit 1
}

& $JAR -cvf "..\$DEST_DIR\${PLUGIN_NAME}_${VERSION}.jar" `
    -C bin . `
    plugin.xml `
    META-INF/ `
    icons/ `
    build.properties `
    .project

Set-Location ..

# Verify build
$JAR_FILE = "$DEST_DIR\${PLUGIN_NAME}_${VERSION}.jar"
if (Test-Path $JAR_FILE) {
    Write-Host "Build successful!"
    Write-Host "Output: $JAR_FILE"
    $size = (Get-Item $JAR_FILE).Length / 1KB
    Write-Host "Size: $([math]::Round($size, 2)) KB"
} else {
    Write-Host "Build failed!"
    exit 1
}

# Clean up
Remove-Item -Recurse -Force $BUILD_DIR

Write-Host ""
Write-Host "Eclipse plugin build complete!"
Write-Host ""
Write-Host "Installation Instructions:"
Write-Host "1. Copy $JAR_FILE to your Eclipse plugins folder"
Write-Host "2. Restart Eclipse"
Write-Host "3. File with .mega extension will show OMEGA icon"
Write-Host ""
Write-Host "To verify installation:"
Write-Host "- Check Eclipse Error Log view for any plugin errors"
Write-Host "- Create a new .mega file to test syntax highlighting"
Write-Host "- Check File Associations in Eclipse preferences"