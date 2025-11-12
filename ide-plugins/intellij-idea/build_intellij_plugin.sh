#!/bin/bash

echo "🔨 Building OMEGA IntelliJ Plugin..."
echo "======================================"

# Set up variables
PLUGIN_NAME="OMEGA-IntelliJ-Plugin"
VERSION="1.0.0"
BUILD_DIR="build"
DIST_DIR="dist"

# Create directories
echo "📁 Creating build directories..."
mkdir -p $BUILD_DIR
mkdir -p $DIST_DIR

# Check Java version
echo "☕ Checking Java version..."
java -version
if [ $? -ne 0 ]; then
    echo "❌ Java not found. Please install Java 11 or higher."
    exit 1
fi

# Download Gradle if not exists
if [ ! -f "gradlew" ]; then
    echo "📦 Installing Gradle wrapper..."
    gradle wrapper --gradle-version 8.0
fi

# Build plugin
echo "🔧 Building plugin with Gradle..."
./gradlew buildPlugin

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Copy built plugin to dist
echo "📦 Copying built plugin..."
cp build/distributions/*.zip $DIST_DIR/

# Verify build
if ls $DIST_DIR/*.zip 1> /dev/null 2>&1; then
    echo "✅ Build successful!"
    echo "📍 Output: $DIST_DIR/"
    ls -la $DIST_DIR/
else
    echo "❌ Build failed - no output files found!"
    exit 1
fi

echo ""
echo "🎉 IntelliJ plugin build complete!"
echo ""
echo "📋 Installation Instructions:"
echo "1. Open IntelliJ IDEA"
echo "2. Go to Settings → Plugins → Install from Disk"
echo "3. Select the .zip file from $DIST_DIR/"
echo "4. Restart IntelliJ IDEA"
echo ""
echo "🔍 To verify installation:"
echo "- Create a new .mega file"
echo "- Check if OMEGA icon appears"
echo "- Test syntax highlighting"
echo ""
echo "🚀 To publish to JetBrains Marketplace:"
echo "1. Get JetBrains account and token"
echo "2. Run: ./gradlew publishPlugin"
echo "3. Or upload manually via JetBrains Plugin Portal"