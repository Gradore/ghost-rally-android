"""Bake surveyed OSM footprints near the start; photos inform facade detail only."""
import json, math, xml.etree.ElementTree as E
from pathlib import Path
root=E.parse(Path(__file__).resolve().parents[2]/'grossraeschen-wide.osm').getroot()
nodes={n.attrib['id']:[float(n.attrib['lat']),float(n.attrib['lon'])] for n in root.findall('node')}
out={'source':'OpenStreetMap API snapshot 2026-10-03; facade and terrace heights interpreted from user photos','buildings':[],'piers':[],'marina':[],'roundabout':[]}
for w in root.findall('way'):
 t={e.attrib['k']:e.attrib['v'] for e in w.findall('tag')}; p=[nodes[e.attrib['ref']] for e in w.findall('nd')]
 if not p:continue
 d=math.hypot((p[0][0]-51.5753876)*111195,(p[0][1]-14.0098543)*69100)
 if d>420:continue
 if 'building' in t:
  kind='hotel' if w.attrib['id']=='150784304' else 'tourist' if w.attrib['id']=='1050578929' else 'generic'
  out['buildings'].append({'id':w.attrib['id'],'p':p,'kind':kind,'h':10.8 if kind=='hotel' else 4.8 if kind=='tourist' else float(t.get('building:levels','2'))*3.2})
 if t.get('man_made')=='pier':out['piers'].append(p)
 if t.get('leisure')=='marina':out['marina']=p
 if t.get('junction')=='roundabout' and d<100:out['roundabout']=p
path=Path(__file__).resolve().parents[1]/'assets/data/start_area.json'
path.write_text(json.dumps(out,separators=(',',':')))
print(len(out['buildings']),'mapped buildings',len(out['piers']),'piers')
