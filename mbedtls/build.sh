#!/bin/bash

set -e

# Function to build and install for a platform
function build_platform() {
    platform=$1
    cmake_args=$2
    
    echo "Configuring mbedtls for $platform"
    cmake mbedtls -B build/$platform \
        -DCMAKE_BUILD_TYPE=Release \
        -DUSE_SHARED_MBEDTLS_LIBRARY=OFF \
        -DUSE_STATIC_MBEDTLS_LIBRARY=ON \
        -DENABLE_PROGRAMS=OFF \
        -DENABLE_TESTING=OFF \
        -DGEN_FILES=OFF \
        -DMBEDTLS_CONFIG_FILE="custom_config.h" \
        $cmake_args
    
    echo "Building mbedtls for $platform"
    cmake --build build/$platform --config Release
    
    echo "Installing mbedtls for $platform"
    mkdir -p $platform/lib
    
    # Copy libraries
    cp build/$platform/library/*.a $platform/lib/
}

# Clean previous builds
rm -rf build macOS iOS tvOS

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
cp -r mbedtls/include/mbedtls include/
cp -r mbedtls/include/psa include/

echo "mbedtls build complete for all Apple platforms"
