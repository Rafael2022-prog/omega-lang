#!/bin/bash

echo "🔨 Building OMEGA Sublime Text Package..."
echo "=============================================="

# Set up variables
PACKAGE_NAME="OMEGA"
VERSION="1.0.0"
BUILD_DIR="build"
DIST_DIR="dist"

# Create directories
echo "📁 Creating build directories..."
mkdir -p $BUILD_DIR
mkdir -p $DIST_DIR

# Copy package files
echo "📂 Copying package files..."
cp OMEGA.sublime-syntax $BUILD_DIR/
cp OMEGA.sublime-settings $BUILD_DIR/
cp package.json $BUILD_DIR/
cp -r icons $BUILD_DIR/

# Create Main.sublime-menu for better integration
cat > $BUILD_DIR/Main.sublime-menu << 'EOF'
[
    {
        "id": "file",
        "children": [
            {
                "id": "new-file",
                "children": [
                    {
                        "caption": "OMEGA Contract",
                        "command": "new_file",
                        "args": {
                            "syntax": "Packages/OMEGA/OMEGA.sublime-syntax",
                            "extension": "mega"
                        }
                    }
                ]
            }
        ]
    },
    {
        "id": "tools",
        "children": [
            {
                "caption": "OMEGA",
                "id": "omega",
                "children": [
                    {
                        "caption": "Compile Contract",
                        "command": "exec",
                        "args": {
                            "cmd": ["omega", "build", "$file"]
                        }
                    },
                    {
                        "caption": "Deploy Contract",
                        "command": "exec", 
                        "args": {
                            "cmd": ["omega", "deploy", "$file"]
                        }
                    }
                ]
            }
        ]
    }
]
EOF

# Create build system
cat > $BUILD_DIR/OMEGA.sublime-build << 'EOF'
{
    "cmd": ["omega", "build", "$file"],
    "file_regex": "^(...*?):([0-9]*):?([0-9]*)",
    "selector": "source.omega",
    "env": {
        "OMEGA_HOME": "/usr/local/lib/omega"
    },
    "variants": [
        {
            "name": "Run Tests",
            "cmd": ["omega", "test", "$file"]
        },
        {
            "name": "Deploy",
            "cmd": ["omega", "deploy", "$file"]
        }
    ],
    "windows": {
        "cmd": ["omega.cmd", "build", "$file"]
    },
    "linux": {
        "cmd": ["omega", "build", "$file"]
    },
    "osx": {
        "cmd": ["omega", "build", "$file"]
    }
}
EOF

# Create package file
cat > $BUILD_DIR/package.json << 'EOF'
{
    "schema_version": "3.0.0",
    "platforms": ["*"],
    "sublime_text": ">=3000",
    "name": "OMEGA Language Support",
    "description": "Syntax highlighting and language support for OMEGA blockchain programming language",
    "author": "OMEGA Language Team",
    "homepage": "https://omegalang.xyz",
    "issues": "https://github.com/omega-lang/omega/issues",
    "donate": "https://omegalang.xyz/donate",
    "buy": null,
    "readme": "https://raw.githubusercontent.com/omega-lang/omega/main/README.md",
    "previous_names": [],
    "labels": ["language", "blockchain", "smart-contracts", "syntax-highlighting"],
    "version": "1.0.0",
    "url": "https://github.com/omega-lang/omega/releases/download/v1.0.0/OMEGA.sublime-package",
    "date": "2025-01-01 00:00:00"
}
EOF

# Create README for package
cat > $BUILD_DIR/README.md << 'EOF'
# OMEGA Language Support for Sublime Text

Syntax highlighting and language support for OMEGA blockchain programming language.

## Features

- ✅ Syntax highlighting for .mega and .omega files
- ✅ Custom file icons for OMEGA files
- ✅ Build system integration
- ✅ Menu integration
- ✅ Snippet support

## Installation

### Package Control (Recommended)
1. Open Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`)
2. Type "Package Control: Install Package"
3. Search for "OMEGA Language Support"
4. Install

### Manual Installation
1. Download the `.sublime-package` file
2. Place in your Sublime Text Packages folder
3. Restart Sublime Text

## Usage

### Creating OMEGA Files
- Use Command Palette: "OMEGA: New Contract"
- Or create files with `.mega` or `.omega` extension

### Building Contracts
- `Ctrl+B` (Windows/Linux) or `Cmd+B` (macOS)
- Select variant: "Run Tests" or "Deploy"

### Commands Available
- **OMEGA: Compile Contract** - Compile current file
- **OMEGA: Deploy Contract** - Deploy to blockchain
- **OMEGA: Run Tests** - Run contract tests

## Configuration

You can customize OMEGA home directory in build settings:
```json
{
    "env": {
        "OMEGA_HOME": "/your/custom/path"
    }
}
```

## Support

- Homepage: https://omegalang.xyz
- Issues: https://github.com/omega-lang/omega/issues
EOF

# Create the sublime-package
echo "📦 Creating sublime-package..."
cd $BUILD_DIR
zip -r ../$DIST_DIR/${PACKAGE_NAME}.sublime-package .
cd ..

# Verify build
if [ -f "$DIST_DIR/${PACKAGE_NAME}.sublime-package" ]; then
    echo "✅ Build successful!"
    echo "📍 Output: $DIST_DIR/${PACKAGE_NAME}.sublime-package"
    echo "📏 Size: $(ls -lh $DIST_DIR/${PACKAGE_NAME}.sublime-package | awk '{print $5}')"
else
    echo "❌ Build failed!"
    exit 1
fi

# Clean up
rm -rf $BUILD_DIR

echo ""
echo "🎉 Sublime Text package build complete!"
echo ""
echo "📋 Installation Instructions:"
echo "1. Copy $DIST_DIR/${PACKAGE_NAME}.sublime-package to:"
echo "   - Windows: %APPDATA%\Sublime Text\Packages\"
echo "   - macOS: ~/Library/Application Support/Sublime Text/Packages/"
echo "   - Linux: ~/.config/sublime-text/Packages/"
echo "2. Restart Sublime Text"
echo "3. Open .mega file to test"
echo ""
echo "🔍 To verify installation:"
echo "- Check View → Syntax menu for 'OMEGA'"
echo "- Create .mega file should show OMEGA icon"
echo "- Use Ctrl+B to build contract"
echo ""
echo "🚀 To publish to Package Control:"
echo "1. Fork https://github.com/wbond/package_control_channel"
echo "2. Add your package to repository.json"
echo "3. Submit pull request"