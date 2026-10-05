"""Bake the user-requested loop from connected OSM ways; never invent bends.
Usage: python tools/bake_lake_loop.py path/to/grossraeschen.osm
OSM snapshot must cover bbox 13.975,51.535,14.060,51.585.
"""
import sys, json, math, heapq, pathlib, xml.etree.ElementTree as ET
from shapely.geometry import LineString, Polygon, Point
from shapely.ops import linemerge
root=pathlib.Path(__file__).resolve().parents[1]
r=ET.parse(sys.argv[1]).getroot()
nodes={x.attrib['id']:(float(x.attrib['lat']),float(x.attrib['lon'])) for x in r.findall('node')}
ways={w.attrib['id']:w for w in r.findall('way')}
def coords(w): return [nodes[x.attrib['ref']] for x in w.findall('nd') if x.attrib['ref'] in nodes]
ring=list(linemerge([LineString(coords(ways[i])) for i in ['1252092947','569931869']]).coords)
lake=Polygon(ring)
def meters(a,b): return math.hypot((a[0]-b[0])*111195,(a[1]-b[1])*111195*math.cos(math.radians(a[0])))
g={}; edge_tags={}
for w in ways.values():
 tags={x.attrib['k']:x.attrib['v'] for x in w.findall('tag')}
 if tags.get('highway') not in {'track','path','footway','cycleway','residential','service','unclassified','tertiary'}: continue
 ids=[x.attrib['ref'] for x in w.findall('nd') if x.attrib['ref'] in nodes]
 for a,b in zip(ids,ids[1:]):
  if lake.buffer(-.00005).contains(Point((nodes[a][0]+nodes[b][0])/2,(nodes[a][1]+nodes[b][1])/2)): continue
  d=meters(nodes[a],nodes[b]); penalty=1 if tags['highway'] in {'track','path','cycleway'} else 1.6
  for u,v in [(a,b),(b,a)]: g.setdefault(u,[]).append((v,d*penalty));edge_tags[u,v]={'way_id':w.attrib['id'],'surface':tags.get('surface','unknown'),'highway':tags['highway']}
start=(51.5753876,14.0098543)
anchors=[start,(51.5745,14.035),(51.5683,14.054),(51.5588,14.057),(51.5480,14.036),(51.5468,14.024),(51.5510,14.006),(51.5585,13.997),(51.57,13.99),start]
ids=[min(g,key=lambda i:meters(nodes[i],p)) for p in anchors]
def path(a,b):
 q=[(0,a)];d={a:0};prev={}
 while q:
  cost,u=heapq.heappop(q)
  if cost!=d[u]:continue
  if u==b:break
  for v,w in g[u]:
   c=cost+w
   if c<d.get(v,float('inf')):d[v]=c;prev[v]=u;heapq.heappush(q,(c,v))
 if b not in d:raise ValueError('Disconnected anchor: '+str(nodes[b]))
 result=[b]
 while result[-1]!=a:result.append(prev[result[-1]])
 return result[::-1]
# Two disjoint shore corridors prevent dead-end anchor excursions.
bottom=min(g,key=lambda i:meters(nodes[i],(51.5426,14.018)))
full_graph=g
# East shore outbound, west shore inbound, without inventing a connection.
g={u:[(v,w) for v,w in edges if not (nodes[v][1]<14.012 and nodes[v][0]<51.573)] for u,edges in full_graph.items()}
outbound=path(ids[0],bottom)
g={u:[(v,w) for v,w in edges if nodes[v][1]<14.036] for u,edges in full_graph.items()}
inbound=path(bottom,ids[0])
route=outbound+inbound[1:]
coordinates=[list(start)]+[list(nodes[i]) for i in route]+[list(start)]
length=sum(meters(a,b) for a,b in zip(coordinates,coordinates[1:]))
p=root/'assets/data/routes.json';data=json.loads(p.read_text());old=data[3];print('old keys',old.keys())
old.update(coordinates=coordinates,length=round(length,1),closed_loop=True,start=list(start),target_seconds=420,source='OpenStreetMap API snapshot 2026-10-03',surface_note='Original OSM alignment; gravel surface is a game adaptation. Some source paths are paved.',way_ids=sorted({edge_tags[a,b]['way_id'] for a,b in zip(route,route[1:])}),node_ids=route,segments=[edge_tags[a,b] for a,b in zip(route,route[1:])])
p.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')))
f=root/'assets/data/map_features.json';features=json.loads(f.read_text())
feature=next(x for x in features if x['state_code']=='12');feature['water']=[[[float(a),float(b)] for a,b in ring[::4]]]
feature['water'][0].append(feature['water'][0][0]);f.write_text(json.dumps(features,ensure_ascii=False,separators=(',',':')))
print('loop',round(length), 'm',len(coordinates),'nodes','7-min average',round(length/420*3.6),'km/h')
