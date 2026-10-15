#!/usr/bin/env python3
import json
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
project = '''{
 archiveVersion = 1; objectVersion = 56;
 objects = {
  A00000000000000000000001 = {isa = PBXProject; buildConfigurationList = A00000000000000000000002; compatibilityVersion = "Xcode 14.0"; mainGroup = A00000000000000000000003; targets = (A00000000000000000000006); };
  A00000000000000000000002 = {isa = XCConfigurationList; buildConfigurations = (A00000000000000000000004); defaultConfigurationName = Release; };
  A00000000000000000000003 = {isa = PBXGroup; children = (A00000000000000000000005); sourceTree = "<group>"; };
  A00000000000000000000004 = {isa = XCBuildConfiguration; name = Release; baseConfigurationReference = A00000000000000000000005; buildSettings = {}; };
  A00000000000000000000005 = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = "CONFIG_PATH"; sourceTree = "<absolute>"; };
  A00000000000000000000006 = {isa = PBXAggregateTarget; name = Check; buildConfigurationList = A00000000000000000000007; buildPhases = (); dependencies = (); };
  A00000000000000000000007 = {isa = XCConfigurationList; buildConfigurations = (A00000000000000000000008); defaultConfigurationName = Release; };
  A00000000000000000000008 = {isa = XCBuildConfiguration; name = Release; buildSettings = {}; };
 };
 rootObject = A00000000000000000000001;
}'''

with tempfile.TemporaryDirectory(prefix='apple-deps-test-') as directory:
    path = Path(directory) / 'Check.xcodeproj'
    path.mkdir()
    (path / 'project.pbxproj').write_text(project.replace('CONFIG_PATH', str(root / 'deps.xcconfig')))

    def settings(sdk, mode):
        command = ['xcodebuild', '-project', str(path), '-target', 'Check',
                   '-configuration', 'Release', '-sdk', sdk,
                   '-showBuildSettings', '-json', 'RETROARCH_APPLE_DEPS=' + str(root)]
        if mode is not None:
            command.append('RETROARCH_APPLE_SDL=' + mode)
        return json.loads(subprocess.check_output(command, stderr=subprocess.DEVNULL))[0]['buildSettings']

    for sdk in ('macosx', 'iphoneos', 'appletvos'):
        default = settings(sdk, None)
        enabled = settings(sdk, 'YES')
        disabled = settings(sdk, 'NO')
        for key in ('OTHER_CFLAGS', 'OTHER_LDFLAGS', 'HEADER_SEARCH_PATHS'):
            assert default.get(key) == enabled.get(key), (sdk, key, 'default changed')
        flags = disabled['OTHER_CFLAGS'].split()
        links = disabled['OTHER_LDFLAGS'].split()
        headers = disabled['HEADER_SEARCH_PATHS'].split()
        assert '-DHAVE_SDL2' not in flags and '-DHAVE_AVDEVICE' not in flags
        assert '-lavdevice' not in links and not any('libSDL' in item for item in links)
        assert not any('/sdl/' in item for item in headers)
        for flag in ('-DHAVE_FFMPEG', '-DHAVE_AVCODEC', '-DHAVE_AVFORMAT', '-DHAVE_SWRESAMPLE', '-DHAVE_SWSCALE'):
            assert flag in flags, (sdk, flag)
        for flag in ('-lavcodec', '-lavformat', '-lswresample', '-lswscale'):
            assert flag in links, (sdk, flag)
        assert '-DHAVE_AVDEVICE' in enabled['OTHER_CFLAGS'].split()
        assert '-lavdevice' in enabled['OTHER_LDFLAGS'].split()
        if sdk != 'appletvos':
            assert '-DHAVE_SDL2' in enabled['OTHER_CFLAGS'].split()
            assert 'libSDL2.a' in enabled['OTHER_LDFLAGS']
            assert '-DHAVE_MICROPHONE' in flags
        print('PASS:', sdk, 'default/YES/NO dependencies')
