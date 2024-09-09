#!/bin/bash

FETCH_ARGS="--all"
MAKE_TARGET="all"
PACKAGE_DIR="Release"

BUILD_IOS12=

args=`getopt dl $*`
set -- $args
while :; do
    echo "$1"
    case "$1" in
        -d)
            FETCH_ARGS="--all --debug"
            MAKE_TARGET="all-debug"
            PACKAGE_DIR="Debug"
            shift
            ;;
        -l)
            BUILD_IOS12=1
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

if [ -n "$BUILD_IOS12" ]; then
    # for iOS 12 we need an older version
    IOS12_VERSION="v1.2.7"
    CURRENT_REV=$( cd MoltenVK ; git rev-parse HEAD )
    CURRENT_XCODE=$( xcode-select -p )
    # v1.2.7 only compiles with Xcode 15.2 or older (not sure how old)
    sudo xcode-select -s ${OLD_XCODE:-/Applications/Xcode-15.2.0.app/Contents/Developer}
    # actual build steps
    pushd MoltenVK
    make clean
    git checkout $IOS12_VERSION
    ./fetchDependencies --ios
    make ios
    popd
    # copy it where retroarch expects
    cp MoltenVK/Package/Release/MoltenVK/dylib/iOS/libMoltenVK.dylib MoltenVK-${IOS12_VERSION}.xcframework/ios-arm64/MoltenVK-${IOS12_VERSION}.framework/MoltenVK-${IOS12_VERSION}
    install_name_tool -id @rpath/MoltenVK-${IOS12_VERSION}.framework/MoltenVK-${IOS12_VERSION} MoltenVK-${IOS12_VERSION}.xcframework/ios-arm64/MoltenVK-${IOS12_VERSION}.framework/MoltenVK-${IOS12_VERSION}
    pushd MoltenVK
    git checkout "$CURRENT_REV"
    popd
    sudo xcode-select -s "$CURRENT_XCODE"
fi

pushd MoltenVK
make clean
./fetchDependencies $FETCH_ARGS
make $MAKE_TARGET
popd

cp -aRp MoltenVK/Package/$PACKAGE_DIR/MoltenVK/dynamic/MoltenVK.xcframework .
