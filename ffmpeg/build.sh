#!/bin/bash

root=$(realpath $(dirname $0))
pushd ${FFMPEG_SRC:-ffmpeg}
versionmin=10.15
ARCHS="arm64 x86_64"
for arch in ${ARCHS} ; do
    rm -f config.h

    if [[ ${arch} == "arm64" ]] ; then
        ffarch=aarch64
    else
        ffarch=x86_64
    fi

    ./configure \
        --prefix=${root}/build/macOS/${arch} \
        --enable-cross-compile \
        --arch=${ffarch} \
        --cc=$(xcrun -f clang) \
        --sysroot="$(xcrun --sdk macosx --show-sdk-path)" \
        --extra-cflags="-arch ${arch} -D__STDC_CONSTANT_MACROS -D_DARWIN_FEATURE_CLOCK_GETTIME=0 -mmacosx-version-min=${versionmin} ${cflags}" \
        --extra-ldflags="-arch ${arch} -isysroot $(xcrun --sdk macosx --show-sdk-path) -mmacosx-version-min=${versionmin}" \
        --target-os=darwin \
        --cpu=generic \
        --enable-pic
    make clean
    make -j
    make install
done

popd
mv ${root}/build/macOS/arm64/include .
for arch in ${ARCHS} ; do
    mkdir -p macOS/lib/${arch}
    mv ${root}/build/macOS/${arch}/lib/lib*.a macOS/lib/${arch}
done
