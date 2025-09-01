# KSCrash

## Overview

KSCrash is a powerful crash reporting library for iOS, tvOS, and macOS applications. This directory contains prebuilt static libraries for all Apple platforms that RetroArch supports.

## Directory Structure

```
kscrash/
├── README.md               # This file
├── build.sh                # Build script for all platforms
├── kscrash.xcconfig        # Xcode configuration settings
├── KSCrash/                # Git submodule - upstream KSCrash source
├── include/                # Consolidated headers for all platforms
├── macosx/lib/             # macOS static libraries (Universal: arm64 + x86_64)
├── iphoneos/lib/           # iOS device static libraries (arm64)
└── appletvos/lib/          # tvOS device static libraries (arm64)
```

## Built Libraries

The following static libraries are built for each platform:

### Core Libraries (Required)
- `libKSCrashCore.a` - Core utilities and definitions
- `libKSCrashRecordingCore.a` - Low-level crash recording functionality
- `libKSCrashRecording.a` - Main crash recording API

### Reporting Libraries (Optional)
- `libKSCrashReportingCore.a` - Core reporting utilities (requires zlib)
- `libKSCrashFilters.a` - Report filtering and processing
- `libKSCrashSinks.a` - Report output destinations
- `libKSCrashInstallations.a` - High-level installation API

### Optional Modules
- `libKSCrashDemangleFilter.a` - C++/Swift symbol demangling
- `libKSCrashBootTimeMonitor.a` - Boot time monitoring
- `libKSCrashDiscSpaceMonitor.a` - Disk space monitoring

## Building

To rebuild the libraries after updating the KSCrash submodule:

```bash
cd kscrash
./build.sh
```

## Platform Support

- **macOS**: 10.14+ (Universal: arm64 + x86_64)
- **iOS**: 12.0+ (Device only: arm64)
- **tvOS**: 12.0+ (Device only: arm64)

## Integration

The libraries are automatically integrated into RetroArch builds via `kscrash.xcconfig`. The preprocessor macro `HAVE_KSCRASH` is used to conditionally compile KSCrash-related code.

## License

KSCrash is licensed under the MIT License. See `KSCrash/LICENSE` for details.