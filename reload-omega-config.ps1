# OMEGA IDE Configuration Reload Script
# This script helps reload TRAE IDE configuration for OMEGA language support

echo "Reloading OMEGA IDE configuration..."

# Check if configuration files exist
if (Test-Path ".trae\icon-theme.json") {
    echo "✅ Icon theme configuration found"
} else {
    echo "❌ Icon theme configuration missing"
}

if (Test-Path ".trae\file-associations.json") {
    echo "✅ File associations configuration found"
} else {
    echo "❌ File associations configuration missing"
}

if (Test-Path ".trae\settings.json") {
    echo "✅ Settings configuration found"
} else {
    echo "❌ Settings configuration missing"
}

if (Test-Path "omega-vscode-extension\images\omega-file-icon-mega.svg") {
    echo "✅ OMEGA icon files found"
} else {
    echo "❌ OMEGA icon files missing"
}

echo ""
echo "Configuration files status:"
echo "- File associations: $(Get-ChildItem .trae\file-associations.json | Select-Object -ExpandProperty FullName)"
echo "- Icon theme: $(Get-ChildItem .trae\icon-theme.json | Select-Object -ExpandProperty FullName)"
echo "- Settings: $(Get-ChildItem .trae\settings.json | Select-Object -ExpandProperty FullName)"
echo "- Test file: $(Get-ChildItem test-icon.mega | Select-Object -ExpandProperty FullName)"

echo ""
echo "To see the changes, please restart TRAE IDE or reload the window."
echo "In TRAE IDE, you can use: Ctrl+Shift+P -> Reload Window"