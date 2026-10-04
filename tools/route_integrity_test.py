"""Geometric integrity checks for the OSM lake loop, independent of renderer."""
import json, math, pathlib
root=pathlib.Path(__file__).resolve().parents[1]
r=json.loads((root/'assets/data/routes.json').read_text())[3]
c=r['coordinates']
def metres(a,b):return math.hypot((b[0]-a[0])*111195,(b[1]-a[1])*111195*math.cos(math.radians(a[0])))
assert c[0]==c[-1]==[51.5753876,14.0098543]
assert len(c)>300
assert max(metres(a,b) for a,b in zip(c,c[1:]))<400, 'unusually long map chord'
length=sum(metres(a,b) for a,b in zip(c,c[1:]))
assert 15000<length<18000
assert len(r['segments'])==len(c)-3
assert min(p[0] for p in c)<51.546 and max(p[1] for p in c)>14.060
print(f'PASS: closed original-way loop, {length:.0f} m, exact start/finish, no >400 m gaps')

# With a supplied original snapshot, validate every edge against its OSM way.
import sys, xml.etree.ElementTree as ET
if len(sys.argv)>1:
 osm=ET.parse(sys.argv[1]).getroot()
 ways={w.attrib['id']:[x.attrib['ref'] for x in w.findall('nd')] for w in osm.findall('way')}
 for (a,b),tags in zip(zip(r['node_ids'],r['node_ids'][1:]),r['segments']):
  ids=ways[tags['way_id']]
  assert any({a,b}=={u,v} for u,v in zip(ids,ids[1:])), 'edge absent from source OSM way'
 print('PASS: every route edge verified against original OSM snapshot')
