#!/bin/bash

# OMEGA MIME Type Installation Script for Linux
# This script installs MIME type definitions and file associations for .mega files

set -e

echo "Installing OMEGA MIME types and file associations..."

# Define paths
MIME_DIR="/usr/share/mime/packages"
ICON_DIR="/usr/share/icons/hicolor"
DESKTOP_DIR="/usr/share/applications"
LOCAL_MIME_DIR="$HOME/.local/share/mime/packages"
LOCAL_ICON_DIR="$HOME/.local/share/icons/hicolor"
LOCAL_DESKTOP_DIR="$HOME/.local/share/applications"

# Function to install system-wide (requires sudo)
install_system_wide() {
    echo "Installing system-wide MIME types..."
    
    # Copy MIME type definition
    sudo cp omega.xml "$MIME_DIR/"
    
    # Copy icons to various sizes
    for size in 16 22 24 32 48 64 128 256; do
        sudo mkdir -p "$ICON_DIR/${size}x${size}/mimetypes"
        sudo cp "icons/application-x-omega-source-${size}.png" "$ICON_DIR/${size}x${size}/mimetypes/" 2>/dev/null || true
    done
    
    # Copy SVG icon
    sudo mkdir -p "$ICON_DIR/scalable/mimetypes"
    sudo cp "../temp-logo.svg" "$ICON_DIR/scalable/mimetypes/application-x-omega-source.svg"
    
    # Update MIME database
    sudo update-mime-database /usr/share/mime
    
    # Update icon cache
    sudo gtk-update-icon-cache /usr/share/icons/hicolor
    
    echo "System-wide installation completed."
}

# Function to install for current user only
install_user_local() {
    echo "Installing user-local MIME types..."
    
    # Create directories
    mkdir -p "$LOCAL_MIME_DIR"
    mkdir -p "$LOCAL_DESKTOP_DIR"
    
    # Copy MIME type definition
    cp omega.xml "$LOCAL_MIME_DIR/"
    
    # Copy icons to various sizes
    for size in 16 22 24 32 48 64 128 256; do
        mkdir -p "$LOCAL_ICON_DIR/${size}x${size}/mimetypes"
        cp "icons/application-x-omega-source-${size}.png" "$LOCAL_ICON_DIR/${size}x${size}/mimetypes/" 2>/dev/null || true
    done
    
    # Copy SVG icon
    mkdir -p "$LOCAL_ICON_DIR/scalable/mimetypes"
    cp "../temp-logo.svg" "$LOCAL_ICON_DIR/scalable/mimetypes/application-x-omega-source.svg"
    
    # Update user MIME database
    update-mime-database "$HOME/.local/share/mime"
    
    # Update user icon cache
    gtk-update-icon-cache "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
    
    echo "User-local installation completed."
}

# Create desktop entry for OMEGA files
create_desktop_entry() {
    cat > omega-editor.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=OMEGA Editor
Comment=Edit OMEGA blockchain source files
Icon=application-x-omega-source
Exec=code %f
Categories=Development;TextEditor;
MimeType=application/x-omega-source;text/x-omega;
NoDisplay=true
EOF
}

# Main installation logic
if [ "$1" = "--system" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "System-wide installation requires sudo privileges."
        echo "Run: sudo $0 --system"
        exit 1
    fi
    install_system_wide
elif [ "$1" = "--user" ]; then
    install_user_local
else
    echo "OMEGA MIME Type Installer"
    echo ""
    echo "Usage:"
    echo "  $0 --system    Install system-wide (requires sudo)"
    echo "  $0 --user      Install for current user only"
    echo ""
    echo "Choose installation type:"
    echo "1) System-wide (all users)"
    echo "2) Current user only"
    read -p "Enter choice (1 or 2): " choice
    
    case $choice in
        1)
            if [ "$EUID" -ne 0 ]; then
                echo "Re-running with sudo for system-wide installation..."
                sudo "$0" --system
            else
                install_system_wide
            fi
            ;;
        2)
            install_user_local
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Create desktop entry
create_desktop_entry

echo ""
echo "Installation completed successfully!"
echo "OMEGA .mega files should now display with the correct icon in file managers."
echo "You may need to restart your file manager or desktop session to see the changes."