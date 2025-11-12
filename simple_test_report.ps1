# OMEGA IDE Plugins - Simple Test Report
Write-Host "OMEGA IDE Plugins - Final Status Report"
Write-Host "======================================"
Write-Host ""

$PLUGIN_DIR = "build\ide-plugins"
Write-Host "Checking plugins in: $PLUGIN_DIR"
Write-Host ""

$PLUGINS = @(
    @{Name="VS Code Extension"; File="*.vsix"; Expected="omega-language-support-1.0.0.vsix"},
    @{Name="Eclipse Plugin"; File="*.jar"; Expected="com.omega.lang.eclipse_1.0.0.jar"},
    @{Name="IntelliJ Plugin"; File="*.zip"; Expected="OMEGA-IntelliJ-Plugin-1.0.0.zip"},
    @{Name="Sublime Text Package"; File="*.sublime-package"; Expected="OMEGA.sublime-package"}
)

$ALL_GOOD = $true

foreach ($plugin in $PLUGINS) {
    Write-Host "Testing $($plugin.Name)..."
    
    $files = Get-ChildItem "$PLUGIN_DIR\$($plugin.File)" -ErrorAction SilentlyContinue
    
    if ($files.Count -gt 0) {
        $file = $files[0]
        $size = [math]::Round($file.Length / 1KB, 2)
        Write-Host "   ✅ FOUND: $($file.Name)"
        Write-Host "   📏 Size: $size KB"
        Write-Host ""
    } else {
        Write-Host "   ❌ NOT FOUND: $($plugin.Expected)"
        Write-Host ""
        $ALL_GOOD = $false
    }
}

Write-Host "Summary"
Write-Host "======="

if ($ALL_GOOD) {
    Write-Host "🎉 ALL PLUGINS READY FOR MARKETPLACE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Package sizes:"
    Get-ChildItem "$PLUGIN_DIR\*" | ForEach-Object {
        $size = [math]::Round($_.Length / 1KB, 2)
        Write-Host "  - $($_.Name): $size KB"
    }
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Manual testing in each IDE"
    Write-Host "2. Submit to marketplaces (see MARKETPLACE_SUBMISSION_GUIDE.md)"
    Write-Host "3. Create GitHub release"
    Write-Host "4. Announce availability"
} else {
    Write-Host "⚠️  Some plugins are missing!" -ForegroundColor Yellow
    Write-Host "Please check the build process."
}