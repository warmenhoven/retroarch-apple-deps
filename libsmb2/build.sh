#!/bin/bash

set -e

cd "$(dirname "$0")"

# Function to build and install for a platform
function build_platform() {
    platform=$1
    cmake_args=$2

    echo "Configuring libsmb2 for $platform"
    cmake libsmb2 -B build/$platform \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_EXAMPLES=OFF \
        -DENABLE_LIBKRB5=OFF \
        -DENABLE_GSSAPI=OFF \
        $cmake_args

    echo "Building libsmb2 for $platform"
    cmake --build build/$platform --config Release

    echo "Installing libsmb2 for $platform"
    mkdir -p $platform/lib

    # Copy library
    cp build/$platform/lib/libsmb2.a $platform/lib/
}

# Clean previous builds
rm -rf build macosx iphoneos iphonesimulator appletvos appletvsimulator

# Build for macOS (Universal Binary - arm64 + x86_64)
build_platform "macosx" \
    "-DCMAKE_OSX_ARCHITECTURES='arm64;x86_64' \
     -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13"

# Build for iOS (arm64 only for modern devices)
build_platform "iphoneos" \
    "-DCMAKE_SYSTEM_NAME=iOS \
     -DCMAKE_OSX_ARCHITECTURES=arm64 \
     -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0"

# Build for iOS Simulator
build_platform "iphonesimulator" \
    "-DCMAKE_SYSTEM_NAME=iOS \
     -DCMAKE_OSX_SYSROOT=iphonesimulator \
     -DCMAKE_OSX_ARCHITECTURES='arm64;x86_64' \
     -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0"

# Build for tvOS
build_platform "appletvos" \
    "-DCMAKE_SYSTEM_NAME=tvOS \
     -DCMAKE_OSX_ARCHITECTURES=arm64 \
     -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0"

# Build for tvOS Simulator
build_platform "appletvsimulator" \
    "-DCMAKE_SYSTEM_NAME=tvOS \
     -DCMAKE_OSX_SYSROOT=appletvsimulator \
     -DCMAKE_OSX_ARCHITECTURES='arm64;x86_64' \
     -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0"

# Create shared include directory after all builds
echo "Creating shared include directory"
mkdir -p include
cp -r libsmb2/include/smb2 include/

echo "libsmb2 build complete for all Apple platforms"
