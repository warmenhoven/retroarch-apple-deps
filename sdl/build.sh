#!/bin/bash

function install() {
    platform=$1
    mkdir -p $platform/include
    mv build/$platform/include-config-release/SDL2/*.h $platform/include
    mkdir -p $platform/lib
    mv build/$platform/libSDL2.a $platform/lib
}

echo Configuring for macOS
cmake ${SDL_SRC:-SDL} -B build/macOS -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13 -DBUILD_SHARED_LIBS=OFF --log-level=ERROR
echo Building for macOS
cmake --build build/macOS -j
echo Installing for macOS
mkdir -p include
mv build/macOS/include/SDL2/*.h include
install macOS

echo Configuring for iOS
cmake ${SDL_SRC:-SDL} -B build/iOS -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF --log-level=ERROR
echo Building for iOS
cmake --build build/iOS -j
echo Installing for iOS
install iOS