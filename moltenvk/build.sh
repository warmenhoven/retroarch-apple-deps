#!/bin/bash

FETCH_ARGS="--all"
MAKE_TARGET="all"
PACKAGE_DIR="Release"

BUILD_LEGACY=

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
            BUILD_LEGACY=1
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

if [ -n "$BUILD_LEGACY" ]; then
    # for iOS 12 and macOS 10.13 we need an older version
    LEGACY_VERSION="v1.2.7"
    LEGACY_GIT_REF="retroarch/v1.2.7"
    CURRENT_REV=$( cd MoltenVK ; git rev-parse HEAD )
    CURRENT_XCODE=$( xcode-select -p )
    # v1.2.7 only compiles with Xcode 15.2 or older (not sure how old)
    sudo xcode-select -s ${OLD_XCODE:-/Applications/Xcode-15.2.0.app/Contents/Developer}
    # actual build steps
    pushd MoltenVK
    make clean
    git checkout $LEGACY_GIT_REF
    ./fetchDependencies --ios --macos
    make ios macos
    popd
    # copy it where retroarch expects
    cp MoltenVK/Package/Release/MoltenVK/dylib/iOS/libMoltenVK.dylib MoltenVK-${LEGACY_VERSION}.xcframework/ios-arm64/MoltenVK-${LEGACY_VERSION}.framework/MoltenVK-${LEGACY_VERSION}
    install_name_tool -id @rpath/MoltenVK-${LEGACY_VERSION}.framework/MoltenVK-${LEGACY_VERSION} MoltenVK-${LEGACY_VERSION}.xcframework/ios-arm64/MoltenVK-${LEGACY_VERSION}.framework/MoltenVK-${LEGACY_VERSION}
    cp MoltenVK/Package/Release/MoltenVK/dylib/macOS/libMoltenVK.dylib MoltenVK-${LEGACY_VERSION}.xcframework/macos-arm64_x86_64/MoltenVK-${LEGACY_VERSION}.framework/Versions/A/MoltenVK-${LEGACY_VERSION}
    install_name_tool -id @rpath/MoltenVK-${LEGACY_VERSION}.framework/Versions/A/MoltenVK-${LEGACY_VERSION} MoltenVK-${LEGACY_VERSION}.xcframework/macos-arm64_x86_64/MoltenVK-${LEGACY_VERSION}.framework/Versions/A/MoltenVK-${LEGACY_VERSION}
    # Create ICD json for Vulkan loader (macOS only)
    mkdir -p MoltenVK-${LEGACY_VERSION}.xcframework/macos-arm64_x86_64/MoltenVK-${LEGACY_VERSION}.framework/Versions/A/Resources
    sed "s|./libMoltenVK.dylib|../MoltenVK-${LEGACY_VERSION}|" \
        MoltenVK/MoltenVK/icd/MoltenVK_icd.json \
        > MoltenVK-${LEGACY_VERSION}.xcframework/macos-arm64_x86_64/MoltenVK-${LEGACY_VERSION}.framework/Versions/A/Resources/MoltenVK_icd.json
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

# Create ICD json for Vulkan loader (macOS only)
mkdir -p MoltenVK.xcframework/macos-arm64_x86_64/MoltenVK.framework/Versions/A/Resources
sed 's|./libMoltenVK.dylib|../MoltenVK|' \
    MoltenVK/MoltenVK/icd/MoltenVK_icd.json \
    > MoltenVK.xcframework/macos-arm64_x86_64/MoltenVK.framework/Versions/A/Resources/MoltenVK_icd.json
