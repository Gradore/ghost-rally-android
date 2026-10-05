"""C# grammar check only. Unity API compilation remains a separate editor check."""
import json
from pathlib import Path
from tree_sitter import Language, Parser
import tree_sitter_c_sharp
parser=Parser(Language(tree_sitter_c_sharp.language()))
root=Path(__file__).resolve().parents[2]
files=sorted((root/'unity/Assets').rglob('*.cs'))
for path in files:
 tree=parser.parse(path.read_bytes())
 assert not tree.root_node.has_error,f'C# grammar failure: {path}'
print(f'PASS: {len(files)} C# files parse; Unity compile/runtime tests still require the Unity Editor')

assemblies = {}
for path in (root/'unity/Assets').rglob('*.asmdef'):
 definition = json.loads(path.read_text())
 assert definition['name'] not in assemblies, f'Duplicate assembly: {path}'
 assemblies[definition['name']] = definition
assert 'GhostRally.Runtime' in assemblies, 'Game scripts need a named runtime assembly for test references'
for name, definition in assemblies.items():
 for reference in definition.get('references', []):
  if reference.startswith('GhostRally.'):
   assert reference in assemblies, f'{name} references missing assembly {reference}'
print(f'PASS: {len(assemblies)} assembly definitions; game/test references resolve')
