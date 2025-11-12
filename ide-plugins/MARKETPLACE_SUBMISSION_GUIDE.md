# 🚀 OMEGA IDE Plugin Marketplace Submission Guide

## 📋 Prerequisites

Before submitting to marketplaces, ensure:
- ✅ All plugins are built and tested
- ✅ Plugin packages are created
- ✅ Documentation is complete
- ✅ Icons are working correctly
- ✅ Test files pass verification

---

## 🔧 VS Code Marketplace

### Account Setup
1. Create Microsoft account at https://marketplace.visualstudio.com
2. Go to "Publish Extensions"
3. Get Personal Access Token from Azure DevOps

### Publishing Steps
```bash
cd ide/vscode-extension
npm install -g vsce
vsce login
vsce publish
```

### Package.json Requirements
- ✅ Unique publisher ID
- ✅ Proper categorization
- ✅ Screenshots and icons
- ✅ Detailed description
- ✅ Repository links

---

## 🌙 Eclipse Marketplace

### Account Setup
1. Create account at https://marketplace.eclipse.org
2. Register as vendor
3. Verify email and complete profile

### Publishing Steps
```bash
cd ide-plugins/eclipse
./build_eclipse_plugin.sh
# Upload JAR file to Eclipse Marketplace
```

### Requirements
- ✅ Plugin description in English
- ✅ License information
- ✅ Update site URL
- ✅ Feature categories
- ✅ Screenshots (800x600 minimum)

---

## 🎯 JetBrains Marketplace

### Account Setup
1. Create JetBrains account
2. Go to https://plugins.jetbrains.com
3. Register as vendor

### Publishing Steps
```bash
cd ide-plugins/intellij-idea
./build_intellij_plugin.sh
# Upload ZIP file via web interface
```

### Requirements
- ✅ Plugin ID: com.omega.lang
- ✅ Detailed description
- ✅ Change notes
- ✅ Plugin logo (40x40, 80x80, 160x160)
- ✅ Screenshots (1240x860 recommended)

---

## 📝 Sublime Text Package Control

### Account Setup
1. Fork https://github.com/wbond/package_control_channel
2. Create branch for your package

### Publishing Steps
```bash
cd ide-plugins/sublime-text
./build_sublime_package.sh
# Create release on GitHub
# Submit PR to package_control_channel
```

### Channel.json Entry
```json
{
    "name": "OMEGA Language Support",
    "description": "Syntax highlighting and language support for OMEGA blockchain programming language",
    "author": "OMEGA Language Team",
    "homepage": "https://omegalang.xyz",
    "issues": "https://github.com/omega-lang/omega/issues",
    "releases": [
        {
            "sublime_text": ">=3000",
            "platforms": ["*"],
            "url": "https://github.com/omega-lang/omega/releases/download/v1.0.0/OMEGA.sublime-package",
            "date": "2025-01-01 00:00:00"
        }
    ]
}
```

---

## 📦 Build All Plugins

### Automated Build Script
```bash
#!/bin/bash
echo "🏗️ Building all OMEGA IDE plugins..."

# VS Code
echo "Building VS Code extension..."
cd ide/vscode-extension && npm run package

# Eclipse
echo "Building Eclipse plugin..."
cd ../ide-plugins/eclipse && ./build_eclipse_plugin.sh

# IntelliJ
echo "Building IntelliJ plugin..."
cd ../intellij-idea && ./build_intellij_plugin.sh

# Sublime Text
echo "Building Sublime Text package..."
cd ../sublime-text && ./build_sublime_package.sh

echo "✅ All plugins built successfully!"
```

---

## 🧪 Pre-submission Checklist

### General
- [ ] Plugin name is unique
- [ ] Version numbers are consistent
- [ ] All dependencies are included
- [ ] Documentation is complete
- [ ] Test files are provided

### VS Code
- [ ] Extension ID is unique
- [ ] Categories are correct
- [ ] Keywords are relevant
- [ ] README is comprehensive
- [ ] Changelog is updated

### Eclipse
- [ ] Plugin ID follows Eclipse conventions
- [ ] License is specified
- [ ] Provider name is set
- [ ] Update site is configured
- [ ] Feature.xml is complete

### IntelliJ
- [ ] Plugin ID is unique
- [ ] Since/until builds are correct
- [ ] Plugin logo is provided
- [ ] Screenshots are included
- [ ] Vendor information is complete

### Sublime Text
- [ ] Package name is unique
- [ ] sublime_text version is correct
- [ ] URLs are accessible
- [ ] Labels are appropriate
- [ ] Previous names are listed

---

## 🚨 Common Issues & Solutions

### VS Code
**Issue**: Extension not showing in marketplace
**Solution**: Check publisher ID and token permissions

**Issue**: Icon not displaying
**Solution**: Verify icon paths in package.json

### Eclipse
**Issue**: Plugin not loading
**Solution**: Check MANIFEST.MF syntax and dependencies

**Issue**: Missing dependencies
**Solution**: Add all required bundles to MANIFEST.MF

### IntelliJ
**Issue**: Plugin compatibility errors
**Solution**: Update since/until build numbers

**Issue**: Icon not showing
**Solution**: Verify icon provider implementation

### Sublime Text
**Issue**: Package not in Package Control
**Solution**: Wait for PR approval (can take weeks)

**Issue**: Syntax not highlighting
**Solution**: Check sublime-syntax file format

---

## 📈 Post-submission

### Monitoring
- Monitor download statistics
- Respond to user reviews
- Fix reported bugs promptly
- Update for new IDE versions

### Updates
- Plan regular updates
- Maintain compatibility
- Add new features
- Improve performance

### Community
- Engage with users
- Collect feedback
- Provide support
- Document improvements

---

## 🎯 Success Metrics

### Download Targets
- **VS Code**: 1,000+ downloads in first month
- **Eclipse**: 500+ installations
- **IntelliJ**: 2,000+ downloads
- **Sublime Text**: 300+ installations

### Quality Metrics
- ⭐ Rating 4.5+ on all platforms
- 🐛 < 5% bug reports vs downloads
- 📈 Monthly active users growth
- 💬 Positive user feedback

---

## 📞 Support

For submission help:
- 📧 Email: support@omegalang.xyz
- 💬 Discord: https://discord.gg/omega-lang
- 🐛 Issues: https://github.com/omega-lang/omega/issues
- 📖 Docs: https://docs.omegalang.xyz

Good luck with your submissions! 🚀