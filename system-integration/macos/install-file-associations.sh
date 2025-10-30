#!/bin/bash

# OMEGA File Association Installation Script for macOS
# This script installs file associations and icons for .mega files on macOS

set -e

echo "Installing OMEGA file associations for macOS..."

# Define paths
OMEGA_APP_PATH="/Applications/OMEGA Editor.app"
PLIST_PATH="$OMEGA_APP_PATH/Contents/Info.plist"
ICON_PATH="$OMEGA_APP_PATH/Contents/Resources"
LAUNCH_SERVICES_DB="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

# Function to create OMEGA Editor app bundle
create_app_bundle() {
    echo "Creating OMEGA Editor app bundle..."
    
    # Create app structure
    sudo mkdir -p "$OMEGA_APP_PATH/Contents/MacOS"
    sudo mkdir -p "$OMEGA_APP_PATH/Contents/Resources"
    
    # Copy Info.plist
    sudo cp Info.plist "$PLIST_PATH"
    
    # Copy icons
    sudo cp ../temp-logo.svg "$ICON_PATH/omega-file-icon.svg"
    sudo cp omega-app-icon.icns "$ICON_PATH/" 2>/dev/null || echo "App icon not found, using default"
    
    # Create executable script
    cat > /tmp/omega-editor << 'EOF'
#!/bin/bash
# OMEGA Editor launcher script
if [ "$#" -eq 0 ]; then
    # No arguments, open VS Code
    open -a "Visual Studio Code"
else
    # Open file with VS Code
    open -a "Visual Studio Code" "$@"
fi
EOF
    
    sudo cp /tmp/omega-editor "$OMEGA_APP_PATH/Contents/MacOS/"
    sudo chmod +x "$OMEGA_APP_PATH/Contents/MacOS/omega-editor"
    
    # Set proper ownership
    sudo chown -R root:wheel "$OMEGA_APP_PATH"
    sudo chmod -R 755 "$OMEGA_APP_PATH"
}

# Function to register file associations
register_file_associations() {
    echo "Registering file associations..."
    
    # Register the app with Launch Services
    if [ -f "$LAUNCH_SERVICES_DB" ]; then
        sudo "$LAUNCH_SERVICES_DB" -f "$OMEGA_APP_PATH"
    fi
    
    # Reset Launch Services database to pick up changes
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
    
    # Set default application for .mega files
    duti -s org.omega-lang.omega-editor .mega all 2>/dev/null || echo "duti not available, manual association required"
}

# Function to install Quick Look plugin
install_quicklook_plugin() {
    echo "Installing Quick Look plugin..."
    
    QUICKLOOK_PATH="$HOME/Library/QuickLook/OmegaQL.qlgenerator"
    
    mkdir -p "$QUICKLOOK_PATH/Contents/MacOS"
    mkdir -p "$QUICKLOOK_PATH/Contents/Resources"
    
    # Create Quick Look Info.plist
    cat > "$QUICKLOOK_PATH/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>org.omega-lang.quicklook</string>
    <key>CFBundleName</key>
    <string>OMEGA Quick Look</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFPlugInDynamicRegistration</key>
    <string>NO</string>
    <key>CFPlugInFactories</key>
    <dict>
        <key>5E2D9680-5022-40FA-B806-43349622E5B9</key>
        <string>QuickLookGeneratorPluginFactory</string>
    </dict>
    <key>CFPlugInTypes</key>
    <dict>
        <key>5E2D9680-5022-40FA-B806-43349622E5B9</key>
        <array>
            <string>org.omega-lang.omega-source</string>
        </array>
    </dict>
    <key>QLSupportedContentTypes</key>
    <array>
        <string>org.omega-lang.omega-source</string>
    </array>
    <key>QLPreviewWidth</key>
    <integer>800</integer>
    <key>QLPreviewHeight</key>
    <integer>600</integer>
</dict>
</plist>
EOF
    
    # Restart Quick Look
    qlmanage -r
}

# Function to create Spotlight importer
create_spotlight_importer() {
    echo "Creating Spotlight importer..."
    
    IMPORTER_PATH="$HOME/Library/Spotlight/OmegaSpotlight.mdimporter"
    
    mkdir -p "$IMPORTER_PATH/Contents/MacOS"
    mkdir -p "$IMPORTER_PATH/Contents/Resources"
    
    # Create Spotlight Info.plist
    cat > "$IMPORTER_PATH/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>org.omega-lang.spotlight</string>
    <key>CFBundleName</key>
    <string>OMEGA Spotlight Importer</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFPlugInDynamicRegistration</key>
    <string>NO</string>
    <key>CFPlugInFactories</key>
    <dict>
        <key>ED2F8E3F-4BF5-4B8D-9B4A-7F8C5E2D1A9B</key>
        <string>MetadataImporterPluginFactory</string>
    </dict>
    <key>CFPlugInTypes</key>
    <dict>
        <key>8B08C4BF-415B-11D8-B3F9-0003936726FC</key>
        <array>
            <string>org.omega-lang.omega-source</string>
        </array>
    </dict>
    <key>MDImporterAttributes</key>
    <array>
        <string>kMDItemContentType</string>
        <string>kMDItemDisplayName</string>
        <string>kMDItemTextContent</string>
        <string>kMDItemTitle</string>
    </array>
    <key>MDImporterDebug</key>
    <false/>
</dict>
</plist>
EOF
    
    # Restart Spotlight
    sudo mdutil -E /
}

# Main installation process
main() {
    echo "OMEGA File Association Installer for macOS"
    echo "=========================================="
    
    # Check if running as admin for system-wide installation
    if [ "$1" = "--system" ]; then
        if [ "$EUID" -ne 0 ]; then
            echo "System-wide installation requires sudo privileges."
            echo "Run: sudo $0 --system"
            exit 1
        fi
        create_app_bundle
    fi
    
    register_file_associations
    install_quicklook_plugin
    create_spotlight_importer
    
    echo ""
    echo "Installation completed successfully!"
    echo ""
    echo "Changes made:"
    echo "- Created OMEGA Editor app bundle (if --system flag used)"
    echo "- Registered .mega file associations"
    echo "- Installed Quick Look plugin for file previews"
    echo "- Created Spotlight importer for search indexing"
    echo ""
    echo "You may need to:"
    echo "1. Restart Finder: killall Finder"
    echo "2. Clear Launch Services cache: /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user"
    echo "3. Log out and log back in for full effect"
}

# Run main function
main "$@"