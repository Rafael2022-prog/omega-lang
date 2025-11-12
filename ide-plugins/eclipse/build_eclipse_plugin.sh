#!/bin/bash

echo "🔨 Building OMEGA Eclipse Plugin..."
echo "====================================="

# Set up variables
PLUGIN_NAME="com.omega.lang.eclipse"
VERSION="1.0.0"
BUILD_DIR="build"
DEST_DIR="dist"

# Create build directories
echo "📁 Creating build directories..."
mkdir -p $BUILD_DIR
mkdir -p $DEST_DIR

# Copy source files
echo "📂 Copying source files..."
cp -r src $BUILD_DIR/
cp plugin.xml $BUILD_DIR/
cp META-INF $BUILD_DIR/ -r
cp icons $BUILD_DIR/ -r
cp build.properties $BUILD_DIR/
cp .project $BUILD_DIR/

# Compile Java classes
echo "☕ Compiling Java classes..."
ECLIPSE_HOME="/Applications/Eclipse.app/Contents/Eclipse"  # Adjust path as needed
if [ ! -d "$ECLIPSE_HOME" ]; then
    echo "⚠️  Eclipse not found at default location. Please set ECLIPSE_HOME environment variable."
    echo "   Example: export ECLIPSE_HOME=/path/to/eclipse"
fi

# Set classpath with Eclipse dependencies
CLASSPATH=""
for jar in $ECLIPSE_HOME/plugins/*.jar; do
    CLASSPATH="$CLASSPATH:$jar"
done

# Compile
echo "Compiling with classpath: $CLASSPATH"
javac -cp "$CLASSPATH" -d $BUILD_DIR/bin src/com/omega/lang/eclipse/*.java
if [ $? -ne 0 ]; then
    echo "❌ Compilation failed!"
    exit 1
fi

# Create plugin JAR
echo "📦 Creating plugin JAR..."
cd $BUILD_DIR
jar -cvf ../$DEST_DIR/${PLUGIN_NAME}_${VERSION}.jar \
    -C bin . \
    plugin.xml \
    META-INF/ \
    icons/ \
    build.properties \
    .project

cd ..

# Verify build
if [ -f "$DEST_DIR/${PLUGIN_NAME}_${VERSION}.jar" ]; then
    echo "✅ Build successful!"
    echo "📍 Output: $DEST_DIR/${PLUGIN_NAME}_${VERSION}.jar"
    echo "📏 Size: $(ls -lh $DEST_DIR/${PLUGIN_NAME}_${VERSION}.jar | awk '{print $5}')"
else
    echo "❌ Build failed!"
    exit 1
fi

# Clean up
rm -rf $BUILD_DIR

echo ""
echo "🎉 Eclipse plugin build complete!"
echo ""
echo "📋 Installation Instructions:"
echo "1. Copy $DEST_DIR/${PLUGIN_NAME}_${VERSION}.jar to your Eclipse plugins folder"
echo "2. Restart Eclipse"
echo "3. File with .mega extension will show OMEGA icon"
echo ""
echo "🔍 To verify installation:"
echo "- Check Eclipse Error Log view for any plugin errors"
echo "- Create a new .mega file to test syntax highlighting"
echo "- Check File Associations in Eclipse preferences"