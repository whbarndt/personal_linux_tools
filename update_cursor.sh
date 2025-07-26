#!/bin/bash
# Cursor Editor Auto-Update Script
# This script automatically downloads and updates Cursor editor to the latest version
# It compares checksums to avoid unnecessary downloads and handles both new installations and updates
# It also automatically updates the .desktop file to point to the new version

set -e  # Exit immediately if any command fails

# Configuration variables
APP_DIR="$HOME/.local/share/cursor-app"        # Directory where Cursor AppImage will be stored
APP_IMAGE_NAME="Cursor-latest-x86_64.AppImage" # Name of the Cursor AppImage file (using latest naming)
CURRENT_APP_IMAGE="$APP_DIR/$APP_IMAGE_NAME"  # Full path to current Cursor installation
DOWNLOAD_URL="https://downloader.cursor.sh/linux/appImage/x64"  # Official Cursor download URL
TEMP_APP_IMAGE="/tmp/cursor-latest.AppImage"  # Temporary file for downloaded AppImage
DESKTOP_FILE="$HOME/.local/share/applications/cursor.desktop"  # Path to the .desktop file

echo "--- Starting Cursor Update ---"

# Check if wget is installed
if ! command -v wget &> /dev/null; then
    echo "Error: wget is required but not installed. Install it with: sudo apt install wget (or equivalent for your distro)."
    exit 1
fi

# Check if there's an existing AppImage with version number and rename it to latest
if [ -d "$APP_DIR" ]; then
    EXISTING_APPIMAGE=$(find "$APP_DIR" -name "Cursor-*-x86_64.AppImage" -type f | head -n 1)
    if [ -n "$EXISTING_APPIMAGE" ] && [ "$EXISTING_APPIMAGE" != "$CURRENT_APP_IMAGE" ]; then
        echo "Found existing AppImage: $(basename "$EXISTING_APPIMAGE")"
        echo "Renaming to latest naming convention..."
        mv "$EXISTING_APPIMAGE" "$CURRENT_APP_IMAGE"
        echo "Renamed successfully."
    fi
fi

echo "Downloading latest version..."

# Download the latest Cursor AppImage to a temporary location
# -q flag makes wget quiet (no progress output), -L follows redirects
wget -q -L -O "$TEMP_APP_IMAGE" "$DOWNLOAD_URL"

# Make the downloaded AppImage executable
chmod +x "$TEMP_APP_IMAGE"

# Check if this is a new installation (no existing Cursor AppImage found)
if [ ! -f "$CURRENT_APP_IMAGE" ]; then
    echo "Installing new version."
    # Create the cursor-app directory if it doesn't exist
    mkdir -p "$APP_DIR"
    # Move the downloaded AppImage to the final location
    mv "$TEMP_APP_IMAGE" "$CURRENT_APP_IMAGE"
    
    # Update the .desktop file to point to the new AppImage
    if [ -f "$DESKTOP_FILE" ]; then
        echo "Updating .desktop file..."
        # Use sed to replace the Exec line with the new path, with backup
        sed -i.bak "s|Exec=.*|Exec=$CURRENT_APP_IMAGE --no-sandbox|" "$DESKTOP_FILE"
        echo "Desktop file updated successfully (backup created as $DESKTOP_FILE.bak)."
    fi
    
    echo "Installed successfully."
    exit 0
fi

echo "Comparing versions..."

# For existing installations, compare checksums to determine if an update is needed
# Calculate SHA256 checksum of the current installed version
CURRENT_CHECKSUM=$(sha256sum "$CURRENT_APP_IMAGE" | awk '{ print $1 }')
echo "Current version checksum: $CURRENT_CHECKSUM"

# Calculate SHA256 checksum of the newly downloaded version
NEW_CHECKSUM=$(sha256sum "$TEMP_APP_IMAGE" | awk '{ print $1 }')
echo "New version checksum: $NEW_CHECKSUM"

# Compare checksums to see if the versions are different
if [ "$CURRENT_CHECKSUM" != "$NEW_CHECKSUM" ]; then
    echo "New version found! Updating..."
    # Replace the old version with the new one
    mv "$TEMP_APP_IMAGE" "$CURRENT_APP_IMAGE"
    
    # Update the .desktop file to point to the new AppImage
    if [ -f "$DESKTOP_FILE" ]; then
        echo "Updating .desktop file..."
        # Use sed to replace the Exec line with the new path, with backup
        sed -i.bak "s|Exec=.*|Exec=$CURRENT_APP_IMAGE --no-sandbox|" "$DESKTOP_FILE"
        echo "Desktop file updated successfully (backup created as $DESKTOP_FILE.bak)."
    fi
    
    echo "Updated successfully."
else
    echo "Already up to date."
    # Clean up the temporary file since no update was needed
    rm "$TEMP_APP_IMAGE"
fi

echo "--- Update Finished ---"