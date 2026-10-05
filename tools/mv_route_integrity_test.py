"""Validate the baked MV stage against an independent OSM XML reference."""
import json, math, pathlib, xml.etree.ElementTree as ET
root=pathlib.Path(__file__).resolve().parents[1]
r=json.loads((root/'assets/data/routes.json').read_text())[16]
scene=json.loads((root/'assets/data/mv_rostock.json').read_text())
osm=ET.parse(root/'assets/data/mv_osm_reference.osm').getroot()
ways={w.attrib['id']:w for w in osm.findall('way')}
nodes={n.attrib['id']:[float(n.attrib['lat']),float(n.attrib['lon'])] for n in osm.findall('node')}
for a in r['anchors']:
 edge=a['source_edge'];aa=nodes[edge['a']];bb=nodes[edge['b']];f=edge['fraction']
 expected=[aa[i]+f*(bb[i]-aa[i]) for i in range(2)]
 assert max(abs(expected[i]-edge['ll'][i]) for i in range(2))<1e-10
 nodes[a['node_id']]=edge['ll']
assert len(r['node_ids'])==len(r['coordinates'])==len(r['segments'])+1
for (a,b),seg in zip(zip(r['node_ids'],r['node_ids'][1:]),r['segments']):
 ids=[n.attrib['ref'] for n in ways[seg['way_id']].findall('nd')]
 if a.startswith('anchor_') or b.startswith('anchor_'):
  def on_segment(p,u,v):
   dx=(v[1]-u[1])*65200;dy=(v[0]-u[0])*111195;px=(p[1]-u[1])*65200;py=(p[0]-u[0])*111195
   f=(px*dx+py*dy)/max(1e-9,dx*dx+dy*dy)
   return -.00001<=f<=1.00001 and math.hypot(px-f*dx,py-f*dy)<.01
  assert any(on_segment(nodes[a],nodes[u],nodes[v]) and on_segment(nodes[b],nodes[u],nodes[v]) for u,v in zip(ids,ids[1:])), 'snapped anchor leaves original edge'
 else:assert any({a,b}=={u,v} for u,v in zip(ids,ids[1:])), 'disconnected route edge' 
assert r['coordinates']==[nodes[n] for n in r['node_ids']], 'coordinates diverged from source'
positions=[r['node_ids'].index(p['node_id']) for p in r['anchors']]
assert positions==sorted(positions), 'waypoint order'
assert [p['code'] for p in r['anchors']]==['35VH+8M7','35PQ+9CH','36Q6+X6V','562C+3XM']
assert max(p['snap_m'] for p in r['anchors'])<50
for b in scene['buildings']:
 w=ways[b['id']];p=[nodes[n.attrib['ref']] for n in w.findall('nd')][:-1]
 assert p==b['p'],'footprint changed'
 assert w.attrib['version']==b['version']
unpaved=sum(s['to']-s['from'] for s in r['segments'] if s['gravel'])
tagged=sum(s['to']-s['from'] for s in r['segments'] if s['gravel'] and not s['surface_assumption'])
print(f'PASS: {len(r["segments"])} original OSM edges; four ordered anchors; {len(scene["buildings"])} original footprints; {unpaved:.0f} m modeled unpaved ({tagged:.0f} m explicitly tagged)')
