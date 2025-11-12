#!/bin/bash

# 🚀 OMEGA IDE Plugin Publisher Script
# This script helps publish all OMEGA IDE plugins to their respective marketplaces

set -e

echo "🚀 Starting OMEGA IDE Plugin Publishing Process..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if all plugins are built
print_status "Verifying plugin builds..."

PLUGINS_BUILT=true

# Check VS Code extension
if [ -f "../ide/vscode-extension/omega-language-support-1.0.0.vsix" ]; then
    print_status "✅ VS Code extension built"
else
    print_warning "❌ VS Code extension not found. Run build script first."
    PLUGINS_BUILT=false
fi

# Check Eclipse plugin
if [ -f "eclipse/plugins/com.omega.lang.eclipse_1.0.0.jar" ]; then
    print_status "✅ Eclipse plugin built"
else
    print_warning "❌ Eclipse plugin not found. Run build script first."
    PLUGINS_BUILT=false
fi

# Check IntelliJ plugin
if [ -f "intellij-idea/build/distributions/OMEGA-IntelliJ-Plugin-1.0.0.zip" ]; then
    print_status "✅ IntelliJ plugin built"
else
    print_warning "❌ IntelliJ plugin not found. Run build script first."
    PLUGINS_BUILT=false
fi

# Check Sublime Text package
if [ -f "sublime-text/build/OMEGA.sublime-package" ]; then
    print_status "✅ Sublime Text package built"
else
    print_warning "❌ Sublime Text package not found. Run build script first."
    PLUGINS_BUILT=false
fi

if [ "$PLUGINS_BUILT" = false ]; then
    print_error "Some plugins are not built. Please run build_all_plugins.sh first."
    exit 1
fi

print_status "All plugins verified! Starting publishing process..."

# VS Code Marketplace Publishing
print_status "📦 Publishing VS Code Extension..."
echo "================================================"
echo "Steps for VS Code Marketplace:"
echo "1. Go to https://marketplace.visualstudio.com/manage"
echo "2. Click 'Publish Extensions'"
echo "3. Upload the .vsix file: ../ide/vscode-extension/omega-language-support-1.0.0.vsix"
echo "4. Fill in the metadata:"
echo "   - Display Name: OMEGA Language Support"
echo "   - Description: Syntax highlighting and language support for OMEGA blockchain programming language"
echo "   - Categories: Programming Languages, Blockchain"
echo "   - Keywords: omega, blockchain, smart-contracts, language"
echo "5. Add screenshots from docs/assets/"
echo "6. Submit for review"
echo ""
echo "VS Code Extension Package: ../ide/vscode-extension/omega-language-support-1.0.0.vsix"
echo ""
read -p "Press Enter when VS Code extension is submitted..."

# Eclipse Marketplace Publishing
print_status "🌙 Publishing Eclipse Plugin..."
echo "================================================"
echo "Steps for Eclipse Marketplace:"
echo "1. Go to https://marketplace.eclipse.org"
echo "2. Click 'Add Content' → 'Create New Listing'"
echo "3. Fill in the plugin information:"
echo "   - Name: OMEGA Language Support"
echo "   - Description: Syntax highlighting and language support for OMEGA blockchain programming language"
echo "   - License: MIT"
echo "   - Category: Programming Languages"
echo "4. Upload the JAR file: eclipse/plugins/com.omega.lang.eclipse_1.0.0.jar"
echo "5. Add screenshots (800x600 minimum)"
echo "6. Provide update site URL (create GitHub Pages site)"
echo "7. Submit for review"
echo ""
echo "Eclipse Plugin Package: eclipse/plugins/com.omega.lang.eclipse_1.0.0.jar"
echo ""
read -p "Press Enter when Eclipse plugin is submitted..."

# IntelliJ Marketplace Publishing
print_status "🎯 Publishing IntelliJ Plugin..."
echo "================================================"
echo "Steps for JetBrains Marketplace:"
echo "1. Go to https://plugins.jetbrains.com"
echo "2. Click 'Upload Plugin'"
echo "3. Upload the ZIP file: intellij-idea/build/distributions/OMEGA-IntelliJ-Plugin-1.0.0.zip"
echo "4. Fill in the plugin information:"
echo "   - Plugin Name: OMEGA Language Support"
echo "   - Description: Syntax highlighting and language support for OMEGA blockchain programming language"
echo "   - Category: Custom Languages"
echo "   - Vendor: OMEGA Language Team"
echo "   - Plugin ID: com.omega.lang"
echo "5. Add plugin logos:"
echo "   - 40x40: docs/assets/omega-logo-40.png"
echo "   - 80x80: docs/assets/omega-logo-80.png"
echo "   - 160x160: docs/assets/omega-logo-160.png"
echo "6. Add screenshots (1240x860 recommended)"
echo "7. Set compatibility range: 2020.1 - 2024.1"
echo "8. Submit for review"
echo ""
echo "IntelliJ Plugin Package: intellij-idea/build/distributions/OMEGA-IntelliJ-Plugin-1.0.0.zip"
echo ""
read -p "Press Enter when IntelliJ plugin is submitted..."

# Sublime Text Package Control Publishing
print_status "📝 Publishing Sublime Text Package..."
echo "================================================"
echo "Steps for Sublime Text Package Control:"
echo "1. Create a GitHub release:"
echo "   - Go to https://github.com/omega-lang/omega/releases"
echo "   - Click 'Create a new release'"
echo "   - Tag: v1.0.0-ide-plugins"
echo "   - Title: OMEGA IDE Plugins v1.0.0"
echo "   - Upload: sublime-text/build/OMEGA.sublime-package"
echo "2. Fork https://github.com/wbond/package_control_channel"
echo "3. Create branch: add-omega-language-support"
echo "4. Add entry to repository/o.json:"
echo ""
cat << 'EOF'
{
    "name": "OMEGA Language Support",
    "description": "Syntax highlighting and language support for OMEGA blockchain programming language",
    "author": "OMEGA Language Team",
    "homepage": "https://omegalang.xyz",
    "issues": "https://github.com/omega-lang/omega/issues",
    "donate": "https://github.com/sponsors/omega-lang",
    "buy": null,
    "readme": "https://raw.githubusercontent.com/omega-lang/omega/main/README.md",
    "previous_names": [],
    "labels": ["language syntax", "blockchain"],
    "version": "1.0.0",
    "url": "https://github.com/omega-lang/omega/releases/download/v1.0.0-ide-plugins/OMEGA.sublime-package",
    "date": "2025-01-01 00:00:00",
    "sublime_text": ">=3000"
}
EOF
echo ""
echo "5. Submit PR to package_control_channel"
echo "6. Wait for approval (can take several weeks)"
echo ""
echo "Sublime Text Package: sublime-text/build/OMEGA.sublime-package"
echo ""
read -p "Press Enter when Sublime Text package is submitted..."

# Create release notes
print_status "📝 Creating Release Notes..."
echo "================================================"
cat > RELEASE_NOTES.md << 'EOF'
# OMEGA IDE Plugins v1.0.0 - Release Notes

## 🎉 What's New

### VS Code Extension
- ✅ Syntax highlighting for .mega and .omega files
- ✅ Language configuration and snippets
- ✅ File icon association
- ✅ Code completion support

### Eclipse Plugin
- ✅ Syntax highlighting with custom rules
- ✅ File association and icon support
- ✅ Editor configuration
- ✅ Plugin architecture ready

### IntelliJ Plugin
- ✅ Language definition and syntax highlighting
- ✅ File type association
- ✅ Custom icons and themes
- ✅ Build system integration

### Sublime Text Package
- ✅ Syntax definition with sublime-syntax
- ✅ File type configuration
- ✅ Custom icons and themes
- ✅ Package Control ready

## 🚀 Installation

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

## 📋 Requirements

- VS Code: Version 1.60.0 or higher
- Eclipse: Version 2020-06 or higher
- IntelliJ IDEA: Version 2020.1 or higher
- Sublime Text: Version 3.0 or higher

## 🐛 Known Issues

- Eclipse plugin requires manual icon configuration in some versions
- IntelliJ plugin may need restart for full syntax highlighting
- Sublime Text package requires Package Control installation

## 🎯 Next Steps

- Add code completion and IntelliSense
- Implement debugging support
- Create project templates
- Add refactoring tools

## 📞 Support

For support and feedback:
- GitHub Issues: https://github.com/omega-lang/omega/issues
- Discord: https://discord.gg/omega-lang
- Email: support@omegalang.xyz

Thank you for using OMEGA IDE Plugins!
EOF

print_status "✅ Release notes created: RELEASE_NOTES.md"

# Final summary
print_status "🎉 Publishing Process Complete!"
echo "================================================"
echo "Summary of submitted packages:"
echo ""
echo "📦 VS Code: ../ide/vscode-extension/omega-language-support-1.0.0.vsix"
echo "🌙 Eclipse: eclipse/plugins/com.omega.lang.eclipse_1.0.0.jar"
echo "🎯 IntelliJ: intellij-idea/build/distributions/OMEGA-IntelliJ-Plugin-1.0.0.zip"
echo "📝 Sublime Text: sublime-text/build/OMEGA.sublime-package"
echo ""
echo "📋 Next steps:"
echo "1. Monitor submission status on each marketplace"
echo "2. Respond to any review feedback"
echo "3. Update plugins based on user feedback"
echo "4. Plan next version with additional features"
echo ""
echo "📞 For support: support@omegalang.xyz"
echo "🔗 Documentation: https://docs.omegalang.xyz"
echo ""
print_status "Thank you for publishing OMEGA IDE Plugins! 🚀"

# Keep terminal open
read -p "Press Enter to exit..."