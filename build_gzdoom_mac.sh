#!/bin/bash

set -e  # Exit on error
set -x  # Debug mode

# Define paths
BUILD_DIR="$(pwd)/build"
INSTALL_DIR="$BUILD_DIR/install"
DMG_NAME="GZDoom.dmg"
ZMusic_DIR="$HOME/zmusic"
ZMusic_INSTALL="/usr/local"
SOUNDFONT_DIR="$BUILD_DIR/soundfonts"
FMBANK_DIR="$BUILD_DIR/fm_banks"
GZDOOM_APP_PATH="$BUILD_DIR/GZDoom.app/Contents/MacOS"

# Install dependencies
echo "🔧 Ensuring dependencies are installed..."
brew install cmake ninja sdl2 jpeg-turbo fluid-synth openal-soft libsndfile mpg123 wget

# Check if ZMusic is installed
if ! pkg-config --exists zmusic; then
    echo "🎵 ZMusic not found! Downloading and building it..."
    rm -rf "$ZMusic_DIR"
    mkdir -p "$ZMusic_DIR"
    cd "$ZMusic_DIR"

    # Fetch the latest ZMusic source code
    wget https://github.com/coelckers/ZMusic/archive/refs/heads/master.zip -O zmusic.zip
    unzip zmusic.zip
    cd ZMusic-master

    # Build ZMusic
    mkdir build && cd build
    cmake .. -G Ninja -DCMAKE_INSTALL_PREFIX="$ZMusic_INSTALL"
    ninja
    sudo ninja install
fi

# Go back to GZDoom directory
cd "$(pwd)"

# Create a clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"  # Ensure install directory exists

# Ensure soundfont and fm_banks directories exist before configuring CMake
mkdir -p "$SOUNDFONT_DIR"
mkdir -p "$FMBANK_DIR"

cd "$BUILD_DIR"

# Configure the project using CMake
echo "⚙️ Configuring CMake..."
cmake .. -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DZMusic_DIR="$ZMusic_INSTALL/lib/cmake/ZMusic" \
    -DSOUNDFONT_DIR="$SOUNDFONT_DIR" \
    -DFMBANK_DIR="$FMBANK_DIR"

# Build the project
echo "🚀 Building GZDoom..."
ninja

# Move soundfonts and fm_banks to the correct location before install
if [ -d "$GZDOOM_APP_PATH/soundfonts" ]; then
    echo "🎵 Moving soundfonts to expected location..."
    mv "$GZDOOM_APP_PATH/soundfonts" "$SOUNDFONT_DIR"
fi

if [ -d "$GZDOOM_APP_PATH/fm_banks" ]; then
    echo "🎵 Moving fm_banks to expected location..."
    mv "$GZDOOM_APP_PATH/fm_banks" "$FMBANK_DIR"
fi

# Install the binary
echo "📦 Installing GZDoom..."
ninja install

# Check if the install directory actually contains the expected files
if [ ! -d "$INSTALL_DIR/bin/gzdoom.app/Contents/MacOS" ]; then
    echo "❌ ERROR: GZDoom did not install into $INSTALL_DIR. Something is overriding the install path."
    exit 1
fi

# Create a .app bundle
#echo "📁 Creating GZDoom.app..."
#mkdir -p "$INSTALL_DIR/GZDoom.app/Contents/MacOS"
#cp -r "$INSTALL_DIR/bin/gzdoom.app" "$INSTALL_DIR/GZDoom.app"
#cp -r "../docs" "$INSTALL_DIR/GZDoom.app/Contents/MacOS/"

# Create the DMG
echo "💽 Creating DMG package..."
hdiutil create -volname "GZDoom" -srcfolder "gzdoom.app" -ov -format UDZO "$HOME/$DMG_NAME"

echo "✅ Build complete! Find your DMG at: $HOME/$DMG_NAME"
