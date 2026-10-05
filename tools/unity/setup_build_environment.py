#!/usr/bin/env python3
"""Install Unity/Android modules, verify the toolchain and optionally start account sign-in.

Install the official Unity CLI first. This script never handles passwords,
commits credentials or claims activation just because installation succeeded.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

VERSION = '6000.0.82f1'


def cli_json(cli, *args):
    result = subprocess.run([str(cli), *args, '--json'], capture_output=True, text=True)
    try:
        response = json.loads(result.stdout)
    except ValueError:
        raise RuntimeError(f'Unity CLI did not return JSON for {args[0]} (exit {result.returncode})')
    unsigned = args == ('auth', 'status') and result.returncode == 3 and response.get('success') and response.get('data', {}).get('loggedIn') is False
    if (result.returncode and not unsigned) or not response.get('success'):
        errors = response.get('errors', [])
        message = '; '.join(e.get('message', e.get('code', 'Unity CLI error')) for e in errors)
        raise RuntimeError(message or f'Unity CLI {" ".join(args)} failed (exit {result.returncode})')
    return response['data']


def verify_tools(editor):
    data = editor.parent/'Data' if sys.platform != 'darwin' else editor.parents[1]
    android = data/'PlaybackEngines/AndroidPlayer'
    dll = android/'UnityEditor.Android.Extensions.dll'
    if not dll.is_file():
        raise RuntimeError(f'Android Build Support missing: {dll}')
    suffix = '.exe' if os.name == 'nt' else ''
    host = 'windows-x86_64' if os.name == 'nt' else 'darwin-x86_64' if sys.platform == 'darwin' else 'linux-x86_64'
    commands = [
        (android/f'OpenJDK/bin/java{suffix}', ['-version']),
        (android/f'NDK/toolchains/llvm/prebuilt/{host}/bin/clang{suffix}', ['--version']),
        (android/f'SDK/platform-tools/adb{suffix}', ['version']),
        (android/f'SDK/build-tools/36.0.0/aapt2{suffix}', ['version']),
    ]
    for tool, args in commands:
        if not tool.is_file():
            raise RuntimeError(f'Missing Android tool: {tool}')
        subprocess.run([str(tool), *args], check=True)
    if not (android/'SDK/platforms/android-36/android.jar').is_file():
        raise RuntimeError('Android API 36 platform is missing')
    print(f'Android module and executable tool checks passed for {editor}', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--unity-cli', type=Path, default=shutil.which('unity'), help='Official Unity CLI executable')
    parser.add_argument('--verify-only', action='store_true', help='Check an existing installation without downloading modules')
    parser.add_argument('--sign-in', action='store_true', help='Start the official browser sign-in flow after installing/verifying tools')
    args = parser.parse_args()
    if not args.unity_cli or not args.unity_cli.is_file():
        parser.error('Install the official Unity CLI, then provide --unity-cli if it is outside PATH')
    if not args.verify_only:
        subprocess.run([str(args.unity_cli), 'install', VERSION, '-m', 'android', '--cm', '--non-interactive'], check=True)
        subprocess.run([str(args.unity_cli), 'install-modules', '-e', VERSION, '-m', 'android', '--cm', '--non-interactive'], check=True)
    root = Path(cli_json(args.unity_cli, 'editors', 'path', VERSION)['path'])
    if sys.platform == 'darwin':
        editor = root/'Unity.app/Contents/MacOS/Unity'
    else:
        editor = root/'Editor'/('Unity.exe' if os.name == 'nt' else 'Unity')
    verify_tools(editor)
    if args.sign_in:
        subprocess.run([str(args.unity_cli), 'auth', 'login'], check=True)
    auth = cli_json(args.unity_cli, 'auth', 'status')
    if not auth.get('loggedIn'):
        raise RuntimeError('Unity account sign-in is still required; use --sign-in or unity auth login')
    cli_json(args.unity_cli, 'license', 'status')
    print('Toolchain and account/license status command completed. Actual editor startup and acceptance tests remain required.')
    print(f'Next: python tools/unity/build_preview.py --unity "{editor}"')


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(f'Build environment incomplete: {error}', file=sys.stderr)
        sys.exit(1)
