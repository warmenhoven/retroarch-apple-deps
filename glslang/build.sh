#!/bin/bash

set -e

cd "$(dirname "$0")"

function build_platform() {
    platform=$1
    cmake_args=$2

    echo "Configuring glslang for $platform"
    cmake glslang -B build/$platform \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_CTEST=OFF \
        -DENABLE_GLSLANG_BINARIES=OFF \
        -DENABLE_HLSL=OFF \
        -DENABLE_OPT=OFF \
        -DCMAKE_CXX_FLAGS="-D_LIBCPP_DISABLE_AVAILABILITY" \
        $cmake_args

    echo "Building glslang for $platform"
    cmake --build build/$platform --config Release

    echo "Installing glslang for $platform"
    cmake --install build/$platform --prefix install/$platform
    mkdir -p $platform/lib
    cp install/$platform/lib/*.a $platform/lib/
}

# Clean previous builds
rm -rf build install macosx iphoneos iphonesimulator appletvos appletvsimulator include

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

# Use headers from any platform install (they're identical)
echo "Creating shared include directory"
cp -r install/macosx/include .

echo "glslang build complete for all Apple platforms"
