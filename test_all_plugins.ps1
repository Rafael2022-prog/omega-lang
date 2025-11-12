# OMEGA IDE Plugins - Final Testing Script
# This script performs final testing of all IDE plugins

Write-Host "OMEGA IDE Plugins - Final Testing"
Write-Host "=================================="
Write-Host ""

$TEST_RESULTS = @()
$PLUGIN_DIR = "build\all-plugins"

# Test 1: VS Code Extension
Write-Host "1. Testing VS Code Extension..."
$VSIX_FILE = Get-ChildItem "$PLUGIN_DIR\*.vsix" -ErrorAction SilentlyContinue
if ($VSIX_FILE) {
    Write-Host "   ✓ VSIX file found: $($VSIX_FILE.Name)"
    Write-Host "   ✓ Size: $([math]::Round($VSIX_FILE.Length/1KB, 2)) KB"
    
    # Test VSIX structure
    $TEMP_DIR = "temp_vscode_test"
    New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null
    Expand-Archive -Path $VSIX_FILE.FullName -DestinationPath $TEMP_DIR -Force
    
    $REQUIRED_FILES = @("package.json", "syntaxes\omega.tmLanguage.json", "snippets\omega.json")
    $MISSING_FILES = @()
    foreach ($file in $REQUIRED_FILES) {
        if (!(Test-Path "$TEMP_DIR\$file")) {
            $MISSING_FILES += $file
        }
    }
    
    if ($MISSING_FILES.Count -eq 0) {
        Write-Host "   ✓ All required files present"
        $TEST_RESULTS += @{Plugin="VS Code";Status="PASS";Details="All files present"}
    } else {
        Write-Host "   ✗ Missing files: $($MISSING_FILES -join ', ')"
        $TEST_RESULTS += @{Plugin="VS Code";Status="FAIL";Details="Missing files: $($MISSING_FILES -join ', ')"}
    }
    
    Remove-Item -Recurse -Force $TEMP_DIR
} else {
    Write-Host "   ✗ VSIX file not found"
    $TEST_RESULTS += @{Plugin="VS Code";Status="FAIL";Details="VSIX file not found"}
}

# Test 2: Eclipse Plugin
Write-Host ""
Write-Host "2. Testing Eclipse Plugin..."
$JAR_FILE = Get-ChildItem "$PLUGIN_DIR\*.jar" -ErrorAction SilentlyContinue
if ($JAR_FILE) {
    Write-Host "   ✓ JAR file found: $($JAR_FILE.Name)"
    Write-Host "   ✓ Size: $([math]::Round($JAR_FILE.Length/1KB, 2)) KB"
    
    # Test JAR structure
    $JAR_CONTENTS = & jar -tf $JAR_FILE.FullName 2>$null
    if ($JAR_CONTENTS -match "plugin.xml" -and $JAR_CONTENTS -match "com/omega/lang/") {
        Write-Host "   ✓ Plugin structure valid"
        $TEST_RESULTS += @{Plugin="Eclipse";Status="PASS";Details="Valid plugin structure"}
    } else {
        Write-Host "   ✗ Invalid plugin structure"
        $TEST_RESULTS += @{Plugin="Eclipse";Status="FAIL";Details="Invalid plugin structure"}
    }
} else {
    Write-Host "   ✗ JAR file not found"
    $TEST_RESULTS += @{Plugin="Eclipse";Status="FAIL";Details="JAR file not found"}
}

# Test 3: IntelliJ Plugin
Write-Host ""
Write-Host "3. Testing IntelliJ Plugin..."
$ZIP_FILE = Get-ChildItem "$PLUGIN_DIR\*.zip" -ErrorAction SilentlyContinue
if ($ZIP_FILE) {
    Write-Host "   ✓ ZIP file found: $($ZIP_FILE.Name)"
    Write-Host "   ✓ Size: $([math]::Round($ZIP_FILE.Length/1KB, 2)) KB"
    
    # Test ZIP structure
    $TEMP_DIR = "temp_intellij_test"
    New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null
    Expand-Archive -Path $ZIP_FILE.FullName -DestinationPath $TEMP_DIR -Force
    
    if (Test-Path "$TEMP_DIR\plugin.xml" -and (Get-ChildItem "$TEMP_DIR\com\omega\lang\*.class" -ErrorAction SilentlyContinue)) {
        Write-Host "   ✓ Plugin structure valid"
        $TEST_RESULTS += @{Plugin="IntelliJ";Status="PASS";Details="Valid plugin structure"}
    } else {
        Write-Host "   ✗ Invalid plugin structure"
        $TEST_RESULTS += @{Plugin="IntelliJ";Status="FAIL";Details="Invalid plugin structure"}
    }
    
    Remove-Item -Recurse -Force $TEMP_DIR
} else {
    Write-Host "   ✗ ZIP file not found"
    $TEST_RESULTS += @{Plugin="IntelliJ";Status="FAIL";Details="ZIP file not found"}
}

# Test 4: Sublime Text Package
Write-Host ""
Write-Host "4. Testing Sublime Text Package..."
$PKG_FILE = Get-ChildItem "$PLUGIN_DIR\*.sublime-package" -ErrorAction SilentlyContinue
if ($PKG_FILE) {
    Write-Host "   ✓ Package file found: $($PKG_FILE.Name)"
    Write-Host "   ✓ Size: $([math]::Round($PKG_FILE.Length/1KB, 2)) KB"
    
    # Test package structure
    $TEMP_DIR = "temp_sublime_test"
    New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null
    Expand-Archive -Path $PKG_FILE.FullName -DestinationPath $TEMP_DIR -Force
    
    if (Test-Path "$TEMP_DIR\*.sublime-syntax" -or Test-Path "$TEMP_DIR\*.tmLanguage") {
        Write-Host "   ✓ Syntax definition found"
        $TEST_RESULTS += @{Plugin="Sublime Text";Status="PASS";Details="Syntax definition present"}
    } else {
        Write-Host "   ✗ No syntax definition found"
        $TEST_RESULTS += @{Plugin="Sublime Text";Status="FAIL";Details="No syntax definition"}
    }
    
    Remove-Item -Recurse -Force $TEMP_DIR
} else {
    Write-Host "   ✗ Package file not found"
    $TEST_RESULTS += @{Plugin="Sublime Text";Status="FAIL";Details="Package file not found"}
}

# Generate test report
Write-Host ""
Write-Host "Test Results Summary"
Write-Host "===================="
Write-Host ""

$PASSED = 0
$FAILED = 0

foreach ($result in $TEST_RESULTS) {
    $status = $result.Status
    $plugin = $result.Plugin
    $details = $result.Details
    
    if ($status -eq "PASS") {
        Write-Host "✅ $plugin - PASS - $details" -ForegroundColor Green
        $PASSED++
    } else {
        Write-Host "❌ $plugin - FAIL - $details" -ForegroundColor Red
        $FAILED++
    }
}

Write-Host ""
Write-Host "Overall Results:"
Write-Host "=================="
Write-Host "Total Plugins: $($TEST_RESULTS.Count)"
Write-Host "Passed: $PASSED" -ForegroundColor Green
Write-Host "Failed: $FAILED" -ForegroundColor Red

if ($FAILED -eq 0) {
    Write-Host ""
    Write-Host "🎉 All plugins passed testing!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Manual testing in each IDE"
    Write-Host "2. Submit to marketplaces"
    Write-Host "3. Create GitHub release"
    Write-Host "4. Update documentation"
    exit 0
} else {
    Write-Host ""
    Write-Host "⚠️  Some plugins failed testing. Please fix issues before release." -ForegroundColor Yellow
    exit 1
}