#!/bin/bash

set -e

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building KSCrash static libraries for Apple platforms${NC}"

# NOTE: This build script includes workarounds for KSCrash 2.3.0 tag issues:
# - Missing #include <stddef.h> for size_t in KSFileUtils.h
# - Missing #include <stdatomic.h> for atomic operations in various files
# - Mismatched pragma diagnostic push/pop in KSObjCApple.h
# These issues were fixed in later commits to master branch

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
KSCRASH_ROOT="$SCRIPT_DIR/KSCrash"
SOURCES_DIR="$KSCRASH_ROOT/Sources"

# Verify KSCrash source exists
if [ ! -d "$KSCRASH_ROOT" ]; then
    echo -e "${RED}Error: KSCrash source directory not found at $KSCRASH_ROOT${NC}"
    echo "Please ensure the KSCrash git submodule is initialized:"
    echo "  git submodule update --init"
    exit 1
fi

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "$SCRIPT_DIR/build"
rm -rf "$SCRIPT_DIR/macosx/lib"/*.a
rm -rf "$SCRIPT_DIR/iphoneos/lib"/*.a
rm -rf "$SCRIPT_DIR/appletvos/lib"/*.a
rm -rf "$SCRIPT_DIR/include"/*

# Create build directories
mkdir -p "$SCRIPT_DIR/build"
mkdir -p "$SCRIPT_DIR/macosx/lib"
mkdir -p "$SCRIPT_DIR/iphoneos/lib"
mkdir -p "$SCRIPT_DIR/appletvos/lib"
mkdir -p "$SCRIPT_DIR/include"

# Common compiler flags (from Package.swift)
COMMON_FLAGS="-Wall -Wextra -Werror"
COMMON_FLAGS="$COMMON_FLAGS -Wconversion -Wsign-conversion -Wshorten-64-to-32"
COMMON_FLAGS="$COMMON_FLAGS -Wimplicit-fallthrough -Wunused-parameter"
COMMON_FLAGS="$COMMON_FLAGS -Wno-strict-prototypes"
# Disable some overly strict warnings that cause issues with KSCrash code
COMMON_FLAGS="$COMMON_FLAGS -Wno-missing-field-initializers"
# Disable pragma warnings for 2.3.0 tag which has mismatched pragma push/pop
COMMON_FLAGS="$COMMON_FLAGS -Wno-unknown-pragmas"

# C-specific flags (include missing headers for 2.3.0 tag)
C_FLAGS="-include stddef.h -include stdbool.h -include stdatomic.h"

# Objective-C specific flags
OBJC_FLAGS="-fobjc-arc"

# C++ specific flags (don't include stdatomic.h as it conflicts with C++ <atomic>)
CXX_FLAGS="-std=gnu++11 -include stddef.h -include stdbool.h"

# Function to compile a single source file
compile_source() {
    local source_file=$1
    local platform=$2
    local output_dir=$3
    local extra_flags=$4
    local include_dirs=$5
    
    local filename=$(basename "$source_file")
    local objname="${filename%.*}.o"
    local output="$output_dir/$objname"
    
    local compiler="clang"
    local flags="$COMMON_FLAGS $extra_flags"
    
    # Determine compiler and flags based on file extension
    case "$source_file" in
        *.cpp|*.cc|*.cxx)
            compiler="clang++"
            flags="$flags $CXX_FLAGS"
            ;;
        *.m|*.mm)
            flags="$flags $OBJC_FLAGS"
            if [[ "$source_file" == *.mm ]]; then
                compiler="clang++"
                flags="$flags $CXX_FLAGS"
            fi
            ;;
        *.c)
            flags="$flags $C_FLAGS"
            ;;
    esac
    
    # Platform-specific settings
    case "$platform" in
        macosx)
            flags="$flags -arch arm64 -arch x86_64 -mmacosx-version-min=10.13"
            ;;
        iphoneos)
            flags="$flags -arch arm64 -miphoneos-version-min=11.0"
            flags="$flags -isysroot $(xcrun --sdk iphoneos --show-sdk-path)"
            ;;
        appletvos)
            flags="$flags -arch arm64 -mtvos-version-min=11.0"
            flags="$flags -isysroot $(xcrun --sdk appletvos --show-sdk-path)"
            ;;
    esac
    
    # Add include directories
    flags="$flags $include_dirs"
    
    # Compile
    $compiler -c "$source_file" -o "$output" $flags
}

# Function to build a library module
build_module() {
    local module_name=$1
    local platform=$2
    local source_dir=$3
    local extra_includes=$4
    
    echo -e "${GREEN}  Building $module_name for $platform...${NC}"
    
    local build_dir="$SCRIPT_DIR/build/$platform/$module_name"
    mkdir -p "$build_dir"
    
    # Common include directories
    local includes="-I$source_dir/include"
    includes="$includes -I$SOURCES_DIR/KSCrashCore/include"
    includes="$includes -I$SOURCES_DIR/KSCrashRecordingCore/include"
    includes="$includes -I$SOURCES_DIR/KSCrashRecording/include"
    includes="$includes -I$SOURCES_DIR/KSCrashRecording"
    includes="$includes -I$SOURCES_DIR/KSCrashRecording/Monitors"
    includes="$includes $extra_includes"
    
    # Find and compile all source files
    local source_files=()
    
    # Add .c files
    while IFS= read -r -d '' file; do
        source_files+=("$file")
    done < <(find "$source_dir" -name "*.c" -not -path "*/Tests/*" -print0 2>/dev/null)
    
    # Add .cpp files
    while IFS= read -r -d '' file; do
        source_files+=("$file")
    done < <(find "$source_dir" -name "*.cpp" -not -path "*/Tests/*" -print0 2>/dev/null)
    
    # Add .m files
    while IFS= read -r -d '' file; do
        source_files+=("$file")
    done < <(find "$source_dir" -name "*.m" -not -path "*/Tests/*" -print0 2>/dev/null)
    
    # Add .mm files
    while IFS= read -r -d '' file; do
        source_files+=("$file")
    done < <(find "$source_dir" -name "*.mm" -not -path "*/Tests/*" -print0 2>/dev/null)
    
    # Compile each source file
    for source_file in "${source_files[@]}"; do
        # Skip test files and samples
        if [[ "$source_file" == *"/Tests/"* ]] || [[ "$source_file" == *"/Samples/"* ]]; then
            continue
        fi
        compile_source "$source_file" "$platform" "$build_dir" "" "$includes"
    done
    
    # Create static library
    local lib_name="lib${module_name}.a"
    local lib_path="$SCRIPT_DIR/$platform/lib/$lib_name"
    
    if ls "$build_dir"/*.o 1> /dev/null 2>&1; then
        # Use libtool instead of ar for better fat binary support
        libtool -static -o "$lib_path" "$build_dir"/*.o 2>/dev/null
        echo -e "${GREEN}    Created $lib_path${NC}"
    else
        echo -e "${YELLOW}    Warning: No object files found for $module_name${NC}"
    fi
}

# Build each module for each platform
for platform in macosx iphoneos appletvos; do
    echo -e "${YELLOW}Building for $platform...${NC}"
    
    # KSCrashCore (base module, no dependencies)
    build_module "KSCrashCore" "$platform" "$SOURCES_DIR/KSCrashCore" ""
    
    # KSCrashRecordingCore (depends on Core)
    build_module "KSCrashRecordingCore" "$platform" "$SOURCES_DIR/KSCrashRecordingCore" ""
    
    # KSCrashReportingCore (depends on Core, links with zlib)
    build_module "KSCrashReportingCore" "$platform" "$SOURCES_DIR/KSCrashReportingCore" ""
    
    # KSCrashRecording (depends on RecordingCore)
    build_module "KSCrashRecording" "$platform" "$SOURCES_DIR/KSCrashRecording" \
        "-I$SOURCES_DIR/KSCrashReportingCore/include"
    
    # KSCrashFilters (depends on Recording, RecordingCore, ReportingCore)
    build_module "KSCrashFilters" "$platform" "$SOURCES_DIR/KSCrashFilters" \
        "-I$SOURCES_DIR/KSCrashReportingCore/include"
    
    # KSCrashSinks (depends on Recording, Filters)
    build_module "KSCrashSinks" "$platform" "$SOURCES_DIR/KSCrashSinks" \
        "-I$SOURCES_DIR/KSCrashFilters/include -I$SOURCES_DIR/KSCrashReportingCore/include"
    
    # KSCrashDemangleFilter (depends on Recording)
    demangle_includes="-I$SOURCES_DIR/KSCrashDemangleFilter"
    demangle_includes="$demangle_includes -I$SOURCES_DIR/KSCrashDemangleFilter/swift"
    demangle_includes="$demangle_includes -I$SOURCES_DIR/KSCrashDemangleFilter/swift/Basic"
    demangle_includes="$demangle_includes -I$SOURCES_DIR/KSCrashDemangleFilter/llvm"
    demangle_includes="$demangle_includes -I$SOURCES_DIR/KSCrashDemangleFilter/llvm/ADT"
    demangle_includes="$demangle_includes -I$SOURCES_DIR/KSCrashDemangleFilter/llvm/Config"
    demangle_includes="$demangle_includes -I$SOURCES_DIR/KSCrashDemangleFilter/llvm/Support"
    build_module "KSCrashDemangleFilter" "$platform" "$SOURCES_DIR/KSCrashDemangleFilter" "$demangle_includes"
    
    # KSCrashInstallations (depends on Filters, Sinks, Recording, DemangleFilter)
    build_module "KSCrashInstallations" "$platform" "$SOURCES_DIR/KSCrashInstallations" \
        "-I$SOURCES_DIR/KSCrashFilters/include -I$SOURCES_DIR/KSCrashSinks/include -I$SOURCES_DIR/KSCrashDemangleFilter/include -I$SOURCES_DIR/KSCrashReportingCore/include"
    
    # Optional monitors
    build_module "KSCrashBootTimeMonitor" "$platform" "$SOURCES_DIR/KSCrashBootTimeMonitor" ""
    build_module "KSCrashDiscSpaceMonitor" "$platform" "$SOURCES_DIR/KSCrashDiscSpaceMonitor" ""
    
    echo ""
done

# Copy headers to include directory
echo -e "${YELLOW}Copying headers...${NC}"

# Function to copy headers from a module
copy_headers() {
    local module_dir=$1
    local dest_subdir=$2
    
    if [ -d "$module_dir/include" ]; then
        mkdir -p "$SCRIPT_DIR/include/$dest_subdir"
        cp -r "$module_dir/include/"* "$SCRIPT_DIR/include/$dest_subdir/" 2>/dev/null || true
    fi
}

# Copy all public headers
copy_headers "$SOURCES_DIR/KSCrashCore" ""
copy_headers "$SOURCES_DIR/KSCrashRecordingCore" ""
copy_headers "$SOURCES_DIR/KSCrashReportingCore" ""
copy_headers "$SOURCES_DIR/KSCrashRecording" ""
copy_headers "$SOURCES_DIR/KSCrashFilters" ""
copy_headers "$SOURCES_DIR/KSCrashSinks" ""
copy_headers "$SOURCES_DIR/KSCrashInstallations" ""
copy_headers "$SOURCES_DIR/KSCrashDemangleFilter" ""
copy_headers "$SOURCES_DIR/KSCrashBootTimeMonitor" ""
copy_headers "$SOURCES_DIR/KSCrashDiscSpaceMonitor" ""

# Also copy some internal headers that might be needed
cp "$SOURCES_DIR/KSCrashRecording/KSCrashReportC.h" "$SCRIPT_DIR/include/" 2>/dev/null || true
cp "$SOURCES_DIR/KSCrashRecording/KSCrashReportFixer.h" "$SCRIPT_DIR/include/" 2>/dev/null || true
cp "$SOURCES_DIR/KSCrashRecording/KSCrashReportVersion.h" "$SCRIPT_DIR/include/" 2>/dev/null || true
cp "$SOURCES_DIR/KSCrashRecordingCore/KSObjCApple.h" "$SCRIPT_DIR/include/" 2>/dev/null || true

# Copy monitor headers
mkdir -p "$SCRIPT_DIR/include/Monitors"
cp "$SOURCES_DIR/KSCrashRecording/Monitors/"*.h "$SCRIPT_DIR/include/Monitors/" 2>/dev/null || true

echo -e "${GREEN}Build complete!${NC}"
echo ""
echo "Libraries have been built for:"
echo "  - macOS (Universal: arm64 + x86_64)"
echo "  - iOS device (arm64)"
echo "  - tvOS device (arm64)"
echo ""
echo "Headers have been copied to: $SCRIPT_DIR/include/"
