#!/usr/bin/env python3
"""Fast structural checks, runnable without installing Godot or Android SDK."""
from pathlib import Path
import configparser
import sys

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    errors = []
    paths = [
        'project.godot', 'main.tscn', 'main.gd',
        'scripts/world.gd', 'scripts/train.gd', 'scripts/passengers.gd',
        'scripts/mission.gd', 'scripts/sound_fx.gd', 'tests/smoke_test.gd',
        'export_presets.cfg', '.github/workflows/android-debug-apk.yml',
    ]
    for path in paths:
        if not (ROOT / path).is_file():
            errors.append(f'Missing file: {path}')
    if errors:
        print('\n'.join(errors), file=sys.stderr)
        return 1

    preset = configparser.ConfigParser(interpolation=None, strict=False)
    preset.read(ROOT / 'export_presets.cfg', encoding='utf-8')
    p = preset['preset.0']
    opt = preset['preset.0.options']
    expected = {
        'name': '"Android"',
        'platform': '"Android"',
    }
    for key, value in expected.items():
        if p.get(key) != value:
            errors.append(f'Incorrect preset {key}: {p.get(key)}')
    if opt.get('gradle_build/use_gradle_build') != 'false':
        errors.append('Debug APK workflow requires the direct Godot Android export template')
    if opt.get('package/signed') != 'true':
        errors.append('Android APK must be signed for install')
    if opt.get('package/unique_name') != '"com.iangumi.littlerailways"':
        errors.append('Unexpected Android app ID')
    if opt.get('architectures/arm64-v8a') != 'true':
        errors.append('arm64 support missing')
    # Export config must NEVER contain private signing credentials.
    for key in ('keystore/debug_password', 'keystore/release_password', 'keystore/release'):
        if opt.get(key, '""') != '""':
            errors.append(f'Secret or local signing path accidentally committed in {key}')
    project_config = configparser.ConfigParser(interpolation=None, strict=False)
    project_config.read(ROOT / 'project.godot', encoding='utf-8')
    if project_config.get('application', 'run/main_scene', fallback='') != '"res://main.tscn"':
        errors.append('Main scene not configured')
    # In Godot 4.4, Android export silently fails on Linux when ETC2/ASTC
    # texture importing is not enabled. Test this before trying to export.
    if project_config.get('rendering', 'textures/vram_compression/import_etc2_astc', fallback='false') != 'true':
        errors.append('Android export requires rendering/textures/vram_compression/import_etc2_astc=true')
    if errors:
        print('Preflight failed:\n' + '\n'.join(errors), file=sys.stderr)
        return 1
    print('PASS: game files present, Android export preset valid, no embedded signing secrets')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
