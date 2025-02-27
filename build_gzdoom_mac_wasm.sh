#!/bin/bash

set -e  # Exit on error
set -x  # Debug mode

# Define paths
BUILD_DIR="$(pwd)/build-wasm"
WAD_FILE="doom2.wad"

# Define ZMusic directory inside GZDoom
ZMusic_DIR="$(pwd)/zmusic"

# Check if ZMusic exists locally
if [ ! -d "$ZMusic_DIR" ]; then
    echo "❌ ERROR: ZMusic directory not found at $ZMusic_DIR."
    echo "Please clone ZMusic inside GZDoom before building:"
    echo "  cd gzdoom && git clone https://github.com/coelckers/ZMusic.git zmusic"
    exit 1
fi

# Build ZMusic from the local repository
echo "🎵 Building ZMusic from $ZMusic_DIR..."
cd "$ZMusic_DIR"

# Apply local modifications to disable FluidSynth and Glib
sed -i.bak 's/add_subdirectory(fluidsynth)/# add_subdirectory(fluidsynth)/g' thirdparty/CMakeLists.txt
sed -i.bak 's/add_subdirectory(thirdparty\/fluidsynth)/# add_subdirectory(thirdparty\/fluidsynth)/g' CMakeLists.txt
sed -i.bak 's/pkg_search_module(GLIB REQUIRED glib-2.0)/# pkg_search_module(GLIB REQUIRED glib-2.0)/g' thirdparty/fluidsynth/src/CMakeLists.txt

# Create a clean build directory
rm -rf build-wasm
mkdir build-wasm && cd build-wasm

# Configure and build ZMusic for WASM
emcmake cmake .. -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$ZMusic_DIR/build-wasm/install" \
    -DBUILD_SHARED_LIBS=OFF \
    -DZMusic_STATIC=ON \
    -DFLUIDSYNTH_BACKEND=OFF \
    -DZMUSIC_USE_FLUIDSYNTH=OFF \
    -DWITH_GLIB=OFF \
    -DWITH_DBUS=OFF \
    -DUSE_ALSA=OFF \
    -DUSE_SYSTEM_ALSA=OFF \
    -DWITH_FLUIDSYNTH=OFF \
    -DUSE_SYSTEM_FLUIDSYNTH=OFF \
    -DUSE_INTERNAL_FLUIDSYNTH=OFF

emmake ninja
emmake ninja install

# Ensure ZMusic CMake package is installed properly
mkdir -p "$ZMusic_DIR/build-wasm/install/lib/cmake/ZMusic"
cp -r "$ZMusic_DIR/build-wasm/ZMusicConfig.cmake" "$ZMusic_DIR/build-wasm/install/lib/cmake/ZMusic/"
cp -r "$ZMusic_DIR/build-wasm/ZMusicConfigVersion.cmake" "$ZMusic_DIR/build-wasm/install/lib/cmake/ZMusic/"


# Return to GZDoom directory
cd ../../

# Build libvpx for WebAssembly in its own directory
echo "🎥 Building libvpx for WebAssembly..."
LIBVPX_DIR="$(pwd)/libvpx-wasm"

# Clone libvpx if not already cloned
if [ ! -d "$LIBVPX_DIR" ]; then
    git clone https://chromium.googlesource.com/webm/libvpx "$LIBVPX_DIR"
fi

cd "$LIBVPX_DIR"

# Create a separate build directory for libvpx
rm -rf build-wasm
mkdir build-wasm && cd build-wasm

# Configure and build libvpx for Emscripten
emconfigure ../configure \
    --prefix="$LIBVPX_DIR/install-wasm" \
    --target=generic-gnu \
    --disable-examples \
    --disable-tools \
    --disable-docs \
    --disable-unit-tests \
    --enable-static \
    --disable-shared

emmake make -j$(nproc)
emmake make install

# Return to GZDoom build directory
cd "$BUILD_DIR"

# Create a clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cd "$BUILD_DIR"

# Ensure ZMusic is correctly installed
ZMusic_CMAKE_PATH="$ZMusic_DIR/build-wasm/install/lib/cmake/ZMusic"

if [ ! -d "$ZMusic_CMAKE_PATH" ]; then
    echo "❌ ERROR: ZMusic CMake directory not found at $ZMusic_CMAKE_PATH"
    echo "Check if ZMusic was built and installed correctly."
    exit 1
fi

# Ensure libzmusic.a exists
if [ ! -f "$ZMusic_DIR/build-wasm/install/lib/libzmusic.a" ]; then
    echo "❌ ERROR: libzmusic.a not found! Something went wrong with the ZMusic build."
    exit 1
fi

# Configure the project using Emscripten
echo "⚙️ Configuring CMake for WebAssembly..."
emcmake cmake .. -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$BUILD_DIR/install" \
    -DZMusic_DIR="$ZMusic_DIR/build-wasm/install/lib/cmake/ZMusic" \
    -DZMUSIC_INCLUDE_DIR="$ZMusic_DIR/build-wasm/install/include" \
    -DZMUSIC_LIBRARIES="$ZMusic_DIR/build-wasm/install/lib/libzmusic.a" \
    -DUSE_OPENAL=OFF \
    -DUSE_FLUIDSYNTH=OFF \
    -DUSE_FMOD=OFF \
    -DUSE_ASM=OFF \
    -DWITH_GTK=OFF \
    -DNO_GTK=ON \
    -DFORCE_CROSSCOMPILE=ON \
    -DCMAKE_CROSSCOMPILING=ON \
    -DCMAKE_SYSTEM_NAME=Emscripten \
    -DCMAKE_EXE_LINKER_FLAGS="-s USE_SDL=2 -s USE_PTHREADS=1 -s ALLOW_MEMORY_GROWTH=1 -s WASM=1" \
    -DSDL2_INCLUDE_DIR="$EM_CACHE/ports/sdl2/include" \
    -DSDL2_LIBRARY="-s USE_SDL=2" \
    -DVPX_FOUND=ON \
    -DVPX_INCLUDE_DIR="$LIBVPX_DIR/install-wasm/include" \
    -DVPX_LIBRARIES="$LIBVPX_DIR/install-wasm/lib/libvpx.a" \
    -DPKG_CONFIG_USE_CMAKE_PREFIX_PATH=ON \
    -DPKG_CONFIG_EXECUTABLE="$(which pkg-config)" \
    -DZDOOM_BUILD_TOOLS=ON


echo "🔧 Building zipdir separately..."
ZIPDIR_BUILD_DIR="$(pwd)/build-wasm/tools-zipdir-build"

# Ensure clean build for zipdir
rm -rf "$ZIPDIR_BUILD_DIR"
mkdir -p "$ZIPDIR_BUILD_DIR"
cd "$ZIPDIR_BUILD_DIR"

# Configure and build zipdir separately
emcmake cmake ../../tools/zipdir -G Ninja
emmake ninja

# Return to main build directory
cd "$BUILD_DIR"

# Copy Doom2.wad before building
cp "$WAD_FILE" "$BUILD_DIR/"

# Build the project
echo "🚀 Building GZDoom for WebAssembly..."
emmake ninja

# Ensure Doom2.wad is available
if [ ! -f "$WAD_FILE" ]; then
    echo "❌ ERROR: $WAD_FILE not found in $(pwd). Please provide a valid Doom2.wad file."
    exit 1
fi

# Convert Doom2.wad into a WebAssembly-compatible format
echo "📁 Preparing Doom2.wad for WebAssembly..."
emcc --preload-file doom2.wad@/doom2.wad --preload-file gzdoom.pk3@/gzdoom.pk3 -o gzdoom.data

# Final message
echo "✅ Build complete! WebAssembly files generated:"
echo "   - GZDoom WASM Binary: $BUILD_DIR/gzdoom.wasm"
echo "   - JavaScript Loader:  $BUILD_DIR/gzdoom.js"
echo "   - Virtual FileSystem: $BUILD_DIR/gzdoom.data"