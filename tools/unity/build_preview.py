#!/usr/bin/env python3
"""Run Unity acceptance tests and produce the Android preview with an activated editor."""
import argparse
import glob
import os
from pathlib import Path
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / 'unity'
VERSION = '6000.0.82f1'


def find_editor():
    override = os.environ.get('GHOST_RALLY_UNITY_EDITOR')
    candidates = [override, shutil.which('Unity'), shutil.which('unity-editor')]
    candidates += glob.glob(str(Path.home() / f'Unity/Hub/Editor/{VERSION}/Editor/Unity'))
    candidates += glob.glob(f'/opt/unity/Editor/Unity')
    candidates += glob.glob(f'/Applications/Unity/Hub/Editor/{VERSION}/Unity.app/Contents/MacOS/Unity')
    candidates += glob.glob(f'C:/Program Files/Unity/Hub/Editor/{VERSION}/Editor/Unity.exe')
    return next((Path(p) for p in candidates if p and Path(p).is_file()), None)


def run(editor, label, args, quit=True):
    logs = PROJECT / 'Logs'
    logs.mkdir(exist_ok=True)
    log = logs / f'{label}.log'
    command = [str(editor), '-batchmode', '-nographics', '-projectPath', str(PROJECT), '-logFile', str(log)]
    if quit:
        command.append('-quit')
    command.extend(args)
    print(f'{label}: running Unity; log: {log}', flush=True)
    result = subprocess.run(command, timeout=5400)
    if result.returncode:
        raise RuntimeError(f'{label} failed (exit {result.returncode}). See {log}. Unity must be activated and Android modules installed.')


def tests(editor, platform):
    result = PROJECT / 'Logs' / f'{platform}-results.xml'
    result.unlink(missing_ok=True)
    run(editor, platform, ['-runTests', '-testPlatform', platform, '-testResults', str(result)], quit=False)
    if not result.is_file():
        raise RuntimeError(f'{platform}: Unity did not write test results')
    report = ET.parse(result).getroot()
    if int(report.get('failed', '0')) or int(report.get('passed', '0')) == 0:
        raise RuntimeError(f'{platform}: tests failed or no test passed. See {result}')
    print(f'{platform}: {report.get("passed")} tests passed', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--unity', type=Path, help='Path to the activated Unity editor executable')
    args = parser.parse_args()
    editor = args.unity or find_editor()
    if not editor or not editor.is_file():
        parser.error(f'Unity {VERSION} not found. Install it with Android Build Support through Unity Hub, activate it, or provide --unity.')
    run(editor, 'prepare', ['-executeMethod', 'GhostRally.Editor.BuildProject.Prepare'])
    tests(editor, 'EditMode')
    tests(editor, 'PlayMode')
    apk = PROJECT / 'Builds' / 'GhostRally-Unity-preview.apk'
    apk.unlink(missing_ok=True)
    run(editor, 'android-preview', ['-buildTarget', 'Android', '-executeMethod', 'GhostRally.Editor.BuildProject.AndroidPreview'])
    with zipfile.ZipFile(apk) as archive:
        if 'lib/arm64-v8a/libunity.so' not in archive.namelist() or 'AndroidManifest.xml' not in archive.namelist():
            raise RuntimeError('Output is missing the Unity ARM64 runtime or Android manifest')
        bad = archive.testzip()
        if bad:
            raise RuntimeError(f'APK archive is damaged: {bad}')
    print(f'APK built and archive verified: {apk} ({apk.stat().st_size // 1048576} MiB)')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, subprocess.TimeoutExpired, OSError, zipfile.BadZipFile) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
