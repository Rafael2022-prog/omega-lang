# Build OMEGA IntelliJ Plugin Manually
Write-Host "Building OMEGA IntelliJ Plugin..."
Write-Host "======================================"

# Set up variables
$PLUGIN_NAME = "OMEGA-IntelliJ-Plugin"
$VERSION = "1.0.0"
$BUILD_DIR = "build"
$DIST_DIR = "dist"

# Create directories
Write-Host "Creating build directories..."
New-Item -ItemType Directory -Force -Path $BUILD_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $DIST_DIR | Out-Null

# Check Java version
Write-Host "Checking Java version..."
java -version
if ($LASTEXITCODE -ne 0) {
    Write-Host "Java not found. Please install Java 11 or higher."
    exit 1
}

# Compile Java classes
Write-Host "Compiling Java classes..."
$JAVAC = (Get-Command javac).Source
if (!(Test-Path $JAVAC)) {
    Write-Host "Java compiler not found!"
    exit 1
}

# Create output directory
New-Item -ItemType Directory -Force -Path "$BUILD_DIR\classes" | Out-Null

# Compile Java files
Write-Host "Compiling Java files..."
$JAVA_FILES = Get-ChildItem -Path "src\com\omega\lang\*.java" -Recurse

foreach ($file in $JAVA_FILES) {
    Write-Host "Compiling $($file.Name)..."
    & $JAVAC -d "$BUILD_DIR\classes" -cp "$BUILD_DIR\classes" $file.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Compilation warning for $($file.Name)"
    }
}

# Copy resources
Write-Host "Copying resources..."
Copy-Item -Recurse -Force "icons" "$BUILD_DIR\classes\com\omega\lang\"

# Create plugin JAR
Write-Host "Creating plugin JAR..."
Set-Location $BUILD_DIR

$JAR = (Get-Command jar).Source
if (!(Test-Path $JAR)) {
    Write-Host "Jar command not found!"
    exit 1
}

# Create plugin structure
& $JAR -cvf "..\$DIST_DIR\${PLUGIN_NAME}-${VERSION}.jar" `
    -C classes . `
    ..\plugin.xml

Set-Location ..

# Create distribution ZIP
Write-Host "Creating distribution ZIP..."
$ZIP_FILE = "$DIST_DIR\${PLUGIN_NAME}-${VERSION}.zip"
Compress-Archive -Path "$BUILD_DIR\classes\*", "plugin.xml" -DestinationPath $ZIP_FILE -Force

# Verify build
if (Test-Path $ZIP_FILE) {
    Write-Host "Build successful!"
    Write-Host "Output: $ZIP_FILE"
    $size = (Get-Item $ZIP_FILE).Length / 1KB
    Write-Host "Size: $([math]::Round($size, 2)) KB"
} else {
    Write-Host "Build failed!"
    exit 1
}

# Clean up
Remove-Item -Recurse -Force $BUILD_DIR

Write-Host ""
Write-Host "IntelliJ plugin build complete!"
Write-Host ""
Write-Host "Installation Instructions:"
Write-Host "1. Open IntelliJ IDEA"
Write-Host "2. Go to Settings → Plugins → Install from Disk"
Write-Host "3. Select the ZIP file from $DIST_DIR"
Write-Host "4. Restart IntelliJ IDEA"
Write-Host ""
Write-Host "To verify installation:"
Write-Host "- Create a new .mega file"
Write-Host "- Check if OMEGA icon appears"
Write-Host "- Test syntax highlighting"