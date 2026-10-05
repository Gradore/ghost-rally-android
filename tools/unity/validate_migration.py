"""Independent binary/coordinate checks; does not claim a Unity build or device test."""
import array,gzip,hashlib,json,math,pathlib,struct
import numpy as np
root=pathlib.Path(__file__).resolve().parents[2];assets=root/'unity/Assets/Resources/Migration'
catalog=json.loads((assets/'catalog.json').read_text());assert len(catalog['cars'])==12 and len(catalog['tracks'])==20
routes=json.loads((root/'assets/data/routes.json').read_text());max_deviation=0
for stage in catalog['tracks']:
 ss=stage['samples'];assert len(ss)>100;assert ss[0]['distance']==0;assert abs(ss[-1]['distance']-stage['length'])<.01
 assert all(b['distance']>a['distance'] for a,b in zip(ss,ss[1:]))
 assert all(3<q['width']<15 and all(math.isfinite(q[k]) for k in ['x','y','z','distance','width']) for q in ss)
 route=routes[stage['routeIndex']]['coordinates'];origin=route[0];angle=stage['rotation'];c,s=math.cos(angle),math.sin(angle)
 points=np.array([[(p[1]-origin[1])*111195*math.cos(math.radians(origin[0])),-(p[0]-origin[0])*111195] for p in route]);points=points@np.array([[c,s],[-s,c]]);points[:,1]*=-1
 a,b=points[:-1],points[1:];delta=b-a;den=np.maximum((delta*delta).sum(axis=1),1e-12)
 sampled=np.array([[q['x'],q['z']] for q in ss]);furthest=0
 for group in np.array_split(sampled,max(1,len(sampled)//100)):
  offsets=group[:,None,:]-a[None,:,:];t=np.clip((offsets*delta).sum(axis=2)/den,0,1);dist=((offsets-t[:,:,None]*delta)**2).sum(axis=2);furthest=max(furthest,float(np.sqrt(dist.min(axis=1)).max()))
 assert furthest<8,(stage['id'],furthest);max_deviation=max(max_deviation,furthest)
print(f'PASS: 20 mapped selections, ordered samples, source-road corridor max {max_deviation:.2f} m')
parts=[next(s for s in catalog['tracks'] if s['routeIndex']==3 and s['wp']==i) for i in range(3)]
for first,second in zip(parts,parts[1:]):assert math.dist([first['samples'][-1][k] for k in ['x','y','z']],[second['samples'][0][k] for k in ['x','y','z']])<.1
print('PASS: three WPs meet at identical endpoints')
manifest=[]
for p in sorted((assets/'Geometry').glob('*.grmesh')):
 stored=p.read_bytes();raw=gzip.decompress(stored) if stored[:2]==b"\x1f\x8b" else stored;assert raw[:4]==b'GRM1';length=struct.unpack_from('<I',raw,4)[0];d=json.loads(raw[8:8+length]);body=memoryview(raw)[8+length:];triangles=0
 for mesh in d['meshes']:
  for primitive in mesh['primitives']:
   n=primitive['vertices'];count=primitive['indices'];stride=primitive.get('stride',32);assert count%3==0 and n>0;off=primitive['offset'];end=off+n*stride+count*4;assert end<=len(body)
   values=np.frombuffer(body[off:off+n*stride],dtype='<f4');assert np.isfinite(values).all();indices=np.frombuffer(body[off+n*stride:end],dtype='<u4');assert indices.max()<n;triangles+=count//3
 for material in d['materials']:
  if material.get('texture'):assert (root/'unity'/material['texture']).is_file(),material['texture']
 for node in d['nodes']:assert -1<=node['mesh']<len(d['meshes']);assert all(0<=child<len(d['nodes']) for child in node['children'])
 if not p.stem.startswith('scenery'):
  names=[n['name'] for n in d['nodes']];assert all(names.count(n)==1 for n in ['wheel_fl','wheel_fr','wheel_rl','wheel_rr']),p.name
 manifest.append({'file':p.name,'sha256':hashlib.sha256(stored).hexdigest(),'bytes':len(stored),'nodes':len(d['nodes']),'meshes':len(d['meshes']),'uniqueTriangles':triangles})
assert len(manifest)==29
print('PASS: 29 geometry containers, all 17 scenery snapshots, finite attributes, valid indices, texture sources and 48 independent wheels')
cal=json.loads((assets/'Calibration/lovo940voc.json').read_text());assert cal['mass']==1350 and cal['wheelRadius']==.317 and cal['wheelbase']==2.77
(assets/'validation-manifest.json').write_text(json.dumps({'geometry':manifest,'sourceCorridorMaxM':max_deviation,'unityEditorExecuted':False},indent=2))
print('PASS: stock Lovo calibration preserved; Unity runtime/build verification still pending')
