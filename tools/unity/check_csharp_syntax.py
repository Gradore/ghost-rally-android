"""C# grammar check only. Unity API compilation remains a separate editor check."""
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
