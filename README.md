# RetroArch Optional Dependencies for Apple Platforms

Across the three Apple platforms (macOS, iOS, tvOS), RetroArch has
optional dependencies on several libraries. For a platform like Linux,
these would typically be provided by the platform, and checked for at
configure time. The build system for Apple platforms is Xcode and
there is not currently a configure-like phase. Instead they are
provided here, with references back to the source code from which they
were compiled.

## Building RetroArch without SDL

With RetroArch using this dependency checkout at
`/usr/local/share/retroarch-apple-deps`, pass `RETROARCH_APPLE_SDL=NO` to
`xcodebuild` when building RetroArch:

```sh
xcodebuild -workspace pkg/apple/RetroArch.xcworkspace -scheme RetroArch \
  -configuration Release RETROARCH_APPLE_SDL=NO
```

The default is `YES`, preserving the existing dependency set. `NO` removes
`HAVE_SDL2`, SDL include paths and SDL static libraries. Native platform
frameworks and microphone support are retained.

The bundled FFmpeg `libavdevice` can reference SDL, so `NO` also omits
`HAVE_AVDEVICE` and `-lavdevice`. FFmpeg camera support is unavailable in this
mode; FFmpeg codecs, resampling, scaling and video recording remain enabled.
The prebuilt libraries do not need to be rebuilt. This setting affects the
RetroArch consumer, not the contents of the supplied archives.

Check the resolved Xcode settings for macOS, iOS and tvOS with
`python3 tests/test_sdl.py` (requires Xcode and those platform SDKs).
