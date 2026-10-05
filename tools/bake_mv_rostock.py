import xml.etree.ElementTree as E,math,heapq,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SNAPSHOTS=sys.argv[1:]
assert len(SNAPSHOTS)==2, 'Pass southern and northern OSM XML snapshots'
from collections import defaultdict
nodes={}; ways={}
for p in SNAPSHOTS:
 r=E.parse(p).getroot()
 for n in r.findall('node'):nodes[n.get('id')]=[float(n.get('lat')),float(n.get('lon'))]
 for w in r.findall('way'):ways[w.get('id')]=([n.get('ref') for n in w.findall('nd')],{t.get('k'):t.get('v') for t in w.findall('tag')},w.get('version'))
def dist(a,b):return math.hypot((a[0]-b[0])*111195,(a[1]-b[1])*65200)
g=defaultdict(list)
for wid,(ids,t,v) in ways.items():
 if t.get('highway') not in ['residential','living_street','unclassified','tertiary','secondary','primary','service','track']:continue
 for a,b in zip(ids,ids[1:]):
  if a not in nodes or b not in nodes:continue
  d=dist(nodes[a],nodes[b]);g[a].append((b,d,wid));g[b].append((a,d,wid))
anchors=[[54.0932875,12.179171875],[54.0859375,12.188609375],[54.0899875,12.210546875],[54.1502125,12.222421875]]
snaps=[]; anchor_edges=[]
for i,p in enumerate(anchors):
 best=(1e99,None)
 for a,links in list(g.items()):
  for b,d,w in links:
   aa=nodes[a];bb=nodes[b];ax=(aa[1]-p[1])*65200;ay=(aa[0]-p[0])*111195;dx=(bb[1]-aa[1])*65200;dy=(bb[0]-aa[0])*111195
   f=max(0,min(1,-(ax*dx+ay*dy)/max(1e-9,dx*dx+dy*dy)))
   delta=math.hypot(ax+f*dx,ay+f*dy)
   if delta<best[0]:best=(delta,(a,b,w,f))
 a,b,w,f=best[1];n='anchor_'+str(i);aa=nodes[a];bb=nodes[b]
 nodes[n]=[aa[0]+f*(bb[0]-aa[0]),aa[1]+f*(bb[1]-aa[1])]
 g[a]=[link for link in g[a] if not (link[0]==b and link[2]==w)]
 g[b]=[link for link in g[b] if not (link[0]==a and link[2]==w)]
 for v in [a,b]:
  d=dist(nodes[n],nodes[v]);g[n].append((v,d,w));g[v].append((n,d,w))
 snaps.append(n);anchor_edges.append({'a':a,'b':b,'way_id':w,'fraction':f,'ll':nodes[n]})
print('snaps',[(n,dist(nodes[n],p),nodes[n]) for n,p in zip(snaps,anchors)])
def path(start,end,gravel):
 q=[(0,start)]; best={start:0};prev={}
 while q:
  cost,n=heapq.heappop(q)
  if cost!=best[n]:continue
  if n==end:break
  for b,d,w in g[n]:
   t=ways[w][1];k=t['highway'];surf=t.get('surface',''); unpaved=surf in ['gravel','fine_gravel','compacted','ground','dirt','unpaved','sand','grass'] or (k=='track' and surf not in ['asphalt','concrete','paving_stones'])
   factor=(.7 if unpaved else 4.5) if gravel else (1.3 if k=='track' else 1)
   if gravel and k in ['primary','secondary']:factor*=3
   if t.get('service')=='driveway':factor*=4
   z=cost+d*factor
   if z<best.get(b,1e99):best[b]=z;prev[b]=(n,w);heapq.heappush(q,(z,b))
 if end not in prev:raise Exception('no connection')
 ids=[end];edges=[]
 while ids[-1]!=start:
  p,w=prev[ids[-1]];edges.append(w);ids.append(p)
 return ids[::-1],edges[::-1]
ids=[];edges=[];wp=[]
for i in range(3):
 a,b=path(snaps[i],snaps[i+1],i==2);wp.append(len(ids));ids+=a if not ids else a[1:];edges+=b
coords=[nodes[n] for n in ids];length=sum(dist(a,b) for a,b in zip(coords,coords[1:])); print('distance',length,'nodes',len(ids))
segments=[];progress=0;aggregate=defaultdict(float)
for a,b,w in zip(coords,coords[1:],edges):
 t=ways[w][1]; d=dist(a,b); s=t.get('surface','unknown'); gravel=s in ['gravel','fine_gravel','compacted','ground','dirt','unpaved','sand','grass'] or (t['highway']=='track' and s not in ['asphalt','concrete','paving_stones'])
 segments.append({'way_id':w,'highway':t['highway'],'surface':s,'name':t.get('name',''),'from':round(progress,2),'to':round(progress+d,2),'gravel':gravel,'width':3.8 if t['highway']=='track' else 5.6,'surface_assumption':s=='unknown'})
 progress+=d;aggregate[(t.get('name',w),s)]+=d
print(sorted(aggregate.items(),key=lambda x:-x[1]))
route={'length':round(length,1),'coordinates':coords,'node_ids':ids,'segments':segments,'way_ids':sorted(set(edges)),'state_code':'13','area':'ROSTOCK–MÖNCHHAGEN','source':'OpenStreetMap contributors','surface':'MIXED','visual_parameters':{'_assumption':True,'street_width':5.6,'track_width':3.8},'anchors':[{'code':c,'ll':p,'node_id':n,'snap_m':round(dist(nodes[n],p),2),'source_edge':anchor_edges[i]} for i,(c,p,n) in enumerate(zip(['35VH+8M7','35PQ+9CH','36Q6+X6V','562C+3XM'],anchors,snaps))]}
routes=json.loads((ROOT/'assets/data/routes.json').read_text())
if len(routes)==16:routes.append(route)
else:routes[16]=route
(ROOT/'assets/data/routes.json').write_text(json.dumps(routes,separators=(',',':')))
# Detailed scenery: retain original polygons, never relocate houses away from the road.
def near(p,limit):
 for a,b in zip(coords,coords[1:]):
  ax=(a[1]-p[1])*65200;ay=(a[0]-p[0])*111195;dx=(b[1]-a[1])*65200;dy=(b[0]-a[0])*111195
  t=max(0,min(1,-(ax*dx+ay*dy)/max(1,dx*dx+dy*dy)))
  if math.hypot(ax+t*dx,ay+t*dy)<limit:return True
 return False
buildings=[];land=[];roads=[];trees=[];rails=[];tree_rows=[];streams=[]
for wid,(ns,t,v) in ways.items():
 p=[nodes[n] for n in ns if n in nodes]
 if len(p)<2:continue
 center=[sum(x[0] for x in p)/len(p),sum(x[1] for x in p)/len(p)]
 if 'building' in t and ns[0]==ns[-1] and len(p)>3 and near(center,160):
  try:h=float(t.get('height','0').replace(' m',''))
  except:h=0
  if not h:
   try:h=float(t.get('building:levels','1' if t['building'] in ['garage','garages','shed','farm_auxiliary'] else '2'))*3.0
   except:h=6
  shape=t.get('roof:shape','hipped' if len(p)==5 and t['building'] not in ['apartments','industrial','commercial','garages'] else 'flat')
  buildings.append({'id':wid,'version':v,'p':p[:-1],'h':h,'kind':t['building'],'roof':shape if shape in ['gabled','hipped'] and len(p)==5 else 'flat','tags':t,'_assumption':True,'height_assumption':'height' not in t and 'building:levels' not in t,'roof_assumption':'roof:shape' not in t})
 if ns[0]==ns[-1] and (t.get('landuse') in ['farmland','meadow','forest','orchard','grass','residential'] or t.get('natural') in ['wood','water','scrub']) and (near(center,600) or any(near(x,250) for x in p)):
  land.append({'id':wid,'p':p[:-1],'kind':t.get('landuse',t.get('natural'))})
 if 'highway' in t and any(near(x,200) for x in p):roads.append({'p':p,'k':'street','highway':t['highway'],'tags':t,'surface':t.get('surface','unknown'),'id':wid})
 if t.get('natural')=='tree_row' and any(near(x,180) for x in p):tree_rows.append(p)
 if t.get('waterway') in ['stream','river','ditch'] and any(near(x,250) for x in p):streams.append(p)
 if t.get('railway')=='rail' and any(near(x,300) for x in p):rails.append(p)
for n in E.parse(SNAPSHOTS[0]).getroot().findall('node')+E.parse(SNAPSHOTS[1]).getroot().findall('node'):
 t={x.get('k'):x.get('v') for x in n.findall('tag')}
 if t.get('natural')=='tree' and near(nodes[n.get('id')],160):trees.append(nodes[n.get('id')])
scene={'source':'OpenStreetMap contributors (ODbL)','retrieved':'2026-10-04','buildings':buildings,'land':land,'roads':roads,'trees':trees,'rails':rails,'tree_rows':tree_rows,'streams':streams,'visual_parameters':{'_assumption':True,'tree_species':'broadleaf','row_spacing_m':11,'woodland_spacing_m':23,'facades':'interpreted'}}
json.dump(scene,open(ROOT/'assets/data/mv_rostock.json','w'),separators=(',',':'));print('SCENERY',len(buildings),len(land),len(roads),len(trees),len(rails))

# Update the offline vector map without replacing the preserved Müritz geometry.
f=ROOT/'assets/data/map_features.json'
features=json.loads(f.read_text())
features=[x for x in features if x.get('route_index')!=16]
for x in features:
 if x['state_code']=='13':x['route_index']=7
features.append({'state_code':'13','route_index':16,'roads':roads,'buildings':buildings,'water':[x['p'] for x in land if x['kind']=='water']})
f.write_text(json.dumps(features,separators=(',',':')))
# Keep a separate pruned copy of the source OSM ways and nodes for offline verification.
needed=set(edges)|{b['id'] for b in buildings}
reference=E.Element('osm',version='0.6',generator='OpenStreetMap contributors (ODbL); pruned source reference')
refs={n for w in needed for n in ways[w][0]}
for n in sorted(refs):
 if n in nodes:E.SubElement(reference,'node',id=n,lat=str(nodes[n][0]),lon=str(nodes[n][1]))
for w in sorted(needed):
 ns,t,v=ways[w];element=E.SubElement(reference,'way',id=w,version=v)
 for n in ns:E.SubElement(element,'nd',ref=n)
 for k,value in t.items():E.SubElement(element,'tag',k=k,v=value)
E.ElementTree(reference).write(ROOT/'assets/data/mv_osm_reference.osm',encoding='utf-8',xml_declaration=True)
