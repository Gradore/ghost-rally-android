#!/usr/bin/env python3
"""Compile game, editor and test assemblies against installed Unity references.

This checks managed APIs without running Unity. It does not resolve project
packages, import assets, compile shaders, execute physics or build an APK.
Package references come from the editor's bundled 3D template cache.
"""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--unity-data', required=True, type=Path, help='Installed Unity Editor/Data directory')
    args = parser.parse_args()
    data = args.unity_data.resolve()
    dotnet = data / 'NetCoreRuntime' / ('dotnet.exe' if (data / 'NetCoreRuntime/dotnet.exe').exists() else 'dotnet')
    compiler = data / 'DotNetSdkRoslyn/csc.dll'
    template_root = data / 'Resources/PackageManager/ProjectTemplates/libcache'
    caches = sorted(template_root.glob('com.unity.template.3d-cross-platform-*/ScriptAssemblies'))
    if not dotnet.is_file() or not compiler.is_file() or not caches:
        parser.error('Installed editor is missing its .NET compiler or bundled 3D template references')
    refs = {}
    for folder in [data/'Managed', data/'Managed/UnityEngine', data/'NetStandard/ref/2.1.0',
                   data/'NetStandard/compat/2.1.0/shims/netfx', data/'NetStandard/compat/2.1.0/shims/netstandard', caches[-1]]:
        for dll in folder.glob('*.dll'):
            if not dll.name.startswith('Assembly-CSharp'):
                refs[dll.stem] = dll
    nunit = data/'Resources/PackageManager/BuiltInPackages/com.unity.ext.nunit/net40/unity-custom/nunit.framework.dll'
    if nunit.is_file():
        refs[nunit.stem] = nunit
    definition = json.loads((ROOT/'unity/Assets/Scripts/GhostRally.Runtime.asmdef').read_text())
    for reference in definition['references']:
        if reference not in refs:
            parser.error(f'Runtime assembly reference is unavailable: {reference}')
    groups = [('Runtime', 'Scripts'), ('Editor', 'Editor'), ('EditModeTests', 'Tests/EditMode'), ('PlayModeTests', 'Tests/PlayMode')]
    print(f'Using editor template cache: {caches[-1]}', flush=True)
    with tempfile.TemporaryDirectory(prefix='ghost-rally-api-') as tmp:
        for name, folder in groups:
            assembly = f'GhostRally.{name}'
            output = Path(tmp)/(assembly+'.dll')
            options = ['-nologo', '-nostdlib+', '-target:library', '-langversion:9.0',
                       '-define:UNITY_EDITOR,UNITY_EDITOR_LINUX,UNITY_6000_0,UNITY_6000_0_OR_NEWER,UNITY_INCLUDE_TESTS',
                       f'-out:{output}']
            options += [f'-r:{path}' for path in refs.values()]
            options += [str(path) for path in sorted((ROOT/'unity/Assets'/folder).glob('*.cs'))]
            response = Path(tmp)/(name+'.rsp')
            response.write_text('\n'.join('"'+option+'"' for option in options))
            subprocess.run([str(dotnet), str(compiler), '@'+str(response)], check=True)
            refs[assembly] = output
            print(f'PASS: {assembly} managed API compilation', flush=True)
    print('Unity import, shader, runtime and Android verification remain separate.')


if __name__ == '__main__':
    main()
