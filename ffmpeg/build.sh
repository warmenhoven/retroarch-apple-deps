#!/bin/bash

root=$(realpath $(dirname $0))

function build_x264() {
    sdk=$1
    arch=$2
    versionmin=$3

    pushd ${X264_SRC:-x264}

    if [ -f Makefile ] ; then
        make clean
    fi

    if [[ ${arch} == "x86_64" ]] ; then
        addl=--disable-asm
    else
        addl=
    fi

    ./configure \
        --prefix="${root}/build/${sdk}/${arch}" \
        --extra-cflags="-m${sdk}-version-min=${versionmin} -arch ${arch}" \
        --extra-asflags="-m${sdk}-version-min=${versionmin} -arch ${arch}" \
        --disable-cli \
        --enable-static \
        --enable-lto \
        --enable-strip \
        --enable-pic \
        --host=${arch}-apple-darwin \
        --sysroot="$(xcrun --sdk ${sdk} --show-sdk-path)" \
        --disable-swscale \
        --disable-ffms \
        --disable-lsmash \
        ${addl}
    make clean
    make -j || exit 1
    make install

    popd
}

function build_libvpx() {
    sdk=$1
    arch=$2
    versionmin=$3

    pushd ${LIBVPX_SRC:-libvpx}

    if [[ ${sdk} == "iphoneos" ]] ; then
        darwin=darwin
    elif [[ ${sdk} == "appletvos" ]] ; then
        darwin=darwintv
    elif [[ ${arch} == "arm64" ]] ; then
        darwin=darwin19
    else
        darwin=darwin17
    fi

    if [ -f Makefile ] ; then
        make -s distclean
    fi

    ./configure \
        --prefix="${root}/build/${sdk}/${arch}" \
        --target=${arch}-${darwin}-gcc \
        --enable-pic \
        --disable-dependency-tracking \
        --disable-install-bins \
        --disable-examples \
        --disable-tools \
        --disable-docs \
        --disable-unit-tests \
        --disable-shared \
        --enable-static
    make -s clean
    make -j || exit 1
    make install

    popd
}

function build_opus() {
    sdk=$1
    arch=$2
    versionmin=$3

    pushd ${OPUS_SRC:-opus}

    if [ -f Makefile ] ; then
        make clean
    fi

    ./autogen.sh
    CFLAGS="-arch ${arch} -m${sdk}-version-min=${versionmin}" ./configure \
        --prefix="${root}/build/${sdk}/${arch}" \
        --host=${arch}-apple-darwin \
        --disable-shared \
        --enable-static \
        --enable-pic \
        --disable-dependency-tracking \
        --disable-doc \
        --with-sysroot="$(xcrun --sdk ${sdk} --show-sdk-path)"
    make clean
    make -j || exit 1
    make install

    popd
}

function build_ffmpeg() {
    sdk=$1
    arch=$2
    versionmin=$3

    pushd ${FFMPEG_SRC:-ffmpeg}

    rm -f config.h

    if [[ ${arch} == "arm64" ]] ; then
        ffarch=aarch64
    else
        ffarch=x86_64
    fi

    if [[ ${sdk} == "appletvos" ]] ; then
        addl=--disable-avfoundation
    else
        addl=
    fi

    if [ -f Makefile ] ; then
        make clean
    fi

    export PKG_CONFIG_PATH="${root}/build/${sdk}/${arch}/lib/pkgconfig"

    ./configure \
        --prefix="${root}/build/${sdk}/${arch}" \
        --enable-cross-compile \
        --arch=${ffarch} \
        --cc=$(xcrun -f clang) \
        --sysroot="$(xcrun --sdk ${sdk} --show-sdk-path)" \
        --extra-cflags="-arch ${arch} -D__STDC_CONSTANT_MACROS -D_DARWIN_FEATURE_CLOCK_GETTIME=0 -m${sdk}-version-min=${versionmin}" \
        --extra-ldflags="-arch ${arch} -isysroot $(xcrun --sdk ${sdk} --show-sdk-path) -m${sdk}-version-min=${versionmin}" \
        --target-os=darwin \
        --cpu=generic \
        --enable-pic \
        --disable-programs \
        --disable-doc \
        --enable-gpl \
        --enable-version3 \
        --disable-postproc \
        --disable-avfilter \
        --disable-metal \
        --disable-audiotoolbox \
        --enable-libx264 \
        --enable-encoder=libx264 \
        --enable-encoder=libx264rgb \
        --enable-libvpx \
        --enable-encoder=libvpx_vp8 \
        --enable-encoder=libvpx_vp9 \
        --enable-encoder=gif \
        --enable-encoder=apng \
        --enable-encoder=aac \
        --enable-encoder=flac \
        --enable-libopus \
        --enable-encoder=libopus \
        ${addl}
    make clean
    make -j || exit 1
    make install

    unset PKG_CONFIG_PATH

    popd
}

function build_all_libs_for() {
    sdk=$1
    arch=$2
    versionmin=$3

    build_x264 $1 $2 $3
    build_libvpx $1 $2 $3
    build_opus $1 $2 $3
    build_ffmpeg $1 $2 $3
}

build_all_libs_for macosx arm64 10.15
build_all_libs_for macosx x86_64 10.13

build_all_libs_for iphoneos arm64 12.0

build_all_libs_for appletvos arm64 11.0
