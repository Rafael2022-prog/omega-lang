# OMEGA IDE Icon Setup Guide

## Overview
OMEGA Language support sudah tersedia untuk beberapa IDE, namun beberapa plugin memerlukan setup manual untuk menampilkan ikon dengan benar.

## ✅ VS Code (Sudah Berfungsi)
VS Code extension sudah lengkap dengan:
- File icons: `omega-file-icon-mega.svg`, `omega-file-icon-dark.svg`, `omega-file-icon-light.svg`
- Language support penuh
- Syntax highlighting
- Auto-install dari marketplace

## 🔧 Eclipse Plugin Setup

### 1. Build Plugin
```bash
cd ide-plugins/eclipse
# Generate Java classes dan build JAR
```

### 2. Install Plugin
1. Copy JAR file ke Eclipse plugins folder
2. Restart Eclipse
3. File `.mega` akan otomatis menampilkan ikon OMEGA

### 3. Struktur Plugin
```
eclipse/
├── plugin.xml
├── icons/
│   └── omega-file-icon.png
├── src/
│   └── com/omega/lang/eclipse/
│       ├── OmegaEditor.java
│       ├── OmegaActionContributor.java
│       ├── OmegaHyperlinkDetector.java
│       ├── OmegaContentProvider.java
│       └── OmegaLabelProvider.java
```

## 🔧 IntelliJ IDEA Plugin Setup

### 1. Build Plugin
```bash
cd ide-plugins/intellij-idea
# Build dengan IntelliJ SDK
```

### 2. Install Plugin
1. Build JAR menggunakan IntelliJ Plugin DevKit
2. Install dari disk di IntelliJ IDEA
3. Restart IDE

### 3. Struktur Plugin
```
intellij-idea/
├── plugin.xml
├── icons/
│   └── omega-file-icon.png
└── src/
    └── com/omega/lang/
        ├── OmegaFileType.java
        ├── OmegaLanguage.java
        ├── icons/
        │   ├── OmegaIconProvider.java
        │   └── OmegaIcons.java
        ├── parser/
        │   └── OmegaParserDefinition.java
        └── highlighting/
            ├── OmegaSyntaxHighlighterFactory.java
            └── OmegaColorSettingsPage.java
```

## 🔧 Sublime Text Setup

### 1. Install Package
```bash
cd ide-plugins/sublime-text
# Copy ke Sublime Text packages folder
```

### 2. Manual Install
1. Copy folder ke: `%APPDATA%\Sublime Text\Packages\User\OMEGA`
2. Restart Sublime Text
3. Atau install via Package Control

### 3. Struktur Package
```
sublime-text/
├── OMEGA.sublime-package
├── OMEGA.sublime-settings
├── icons/
│   └── file_type_omega.png
└── syntax/
    └── omega.tmLanguage
```

## 🎨 Icon Files
Semua plugin menggunakan ikon yang sama:
- Source: `omega-vscode-extension/images/omega-file-icon-mega.svg`
- Format: PNG untuk Eclipse & IntelliJ, SVG untuk VS Code
- Warna: Biru cyan (#00D4FF) dengan background gelap

## 🚀 Build Script
Gunakan script berikut untuk build semua plugin:

```bash
#!/bin/bash
echo "Building OMEGA IDE Plugins..."

# VS Code (sudah ready)
echo "✅ VS Code extension ready"

# Eclipse
echo "Building Eclipse plugin..."
cd ide-plugins/eclipse
# Add build commands here

# IntelliJ
echo "Building IntelliJ plugin..."
cd ../intellij-idea
# Add build commands here

# Sublime Text
echo "Building Sublime Text package..."
cd ../sublime-text
# Add build commands here

echo "All plugins built successfully!"
```

## 📋 Troubleshooting

### Icon tidak muncul?
1. **Restart IDE** setelah install plugin
2. **Clear cache** IDE jika perlu
3. **Check file extension** `.mega` atau `.omega`
4. **Verify plugin installation** di IDE settings

### Plugin tidak terdeteksi?
1. **Check plugin compatibility** dengan IDE version
2. **Update IDE** ke versi terbaru
3. **Reinstall plugin** dengan cara yang benar

## 🔗 Download Links
- VS Code: Search "OMEGA Language Support" di marketplace
- Eclipse: Build dari source di `ide-plugins/eclipse/`
- IntelliJ: Build dari source di `ide-plugins/intellij-idea/`
- Sublime Text: Package di `ide-plugins/sublime-text/`

## 📞 Support
Untuk masalah plugin, buka issue di repository OMEGA atau hubungi support@omegalang.xyz