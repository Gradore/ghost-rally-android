"""Convert our own GLB scene snapshots to Unity's importable GRMesh container.
No external game APK contents are accepted. Reflect Z and triangle winding once.
"""
import argparse,base64,gzip,hashlib,json,pathlib,struct

def convert(path,output,textures):
 raw=path.read_bytes();assert raw[:4]==b'glTF'
 offset=12;doc=None;binary=b''
 while offset<len(raw):
  n,kind=struct.unpack_from('<II',raw,offset);chunk=raw[offset+8:offset+8+n];offset+=8+n
  if kind==0x4e4f534a:doc=json.loads(chunk)
  elif kind==0x004e4942:binary=chunk
 def accessor(index):
  a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
  formats={5120:'b',5121:'B',5122:'h',5123:'H',5125:'I',5126:'f'};dim={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
  fmt='<'+formats[a['componentType']]*dim;size=struct.calcsize(fmt);stride=v.get('byteStride',size);start=v.get('byteOffset',0)+a.get('byteOffset',0)
  return [struct.unpack_from(fmt,binary,start+i*stride) for i in range(a['count'])]
 images=[]
 for image in doc.get('images',[]):
  if 'bufferView' in image:
   v=doc['bufferViews'][image['bufferView']];b=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
  elif image['uri'].startswith('data:'):b=base64.b64decode(image['uri'].split(',',1)[1])
  else:b=(path.parent/image['uri']).read_bytes()
  ext='.jpg' if b[:2]==b'\xff\xd8' else '.png';name=hashlib.sha256(b).hexdigest()[:24]+ext;textures.mkdir(parents=True,exist_ok=True);(textures/name).write_bytes(b);images.append('Assets/Resources/Migration/Textures/'+name)
 mats=[]
 for m in doc.get('materials',[]):
  p=m.get('pbrMetallicRoughness',{});t=p.get('baseColorTexture',{}).get('index',-1)
  mats.append({'name':m.get('name','Material'),'color':p.get('baseColorFactor',[1,1,1,1]),'metallic':p.get('metallicFactor',0),'roughness':p.get('roughnessFactor',1),'emission':m.get('emissiveFactor',[0,0,0]),'cutout':m.get('alphaMode')=='MASK','cutoff':m.get('alphaCutoff',.5),'texture':images[doc['textures'][t]['source']] if t>=0 else '', 'doubleSided':m.get('doubleSided',False)})
 # A single binary block with float attributes and uint32 indices per primitive.
 block=bytearray();meshes=[]
 for mesh in doc.get('meshes',[]):
  primitives=[]
  for p in mesh['primitives']:
   assert p.get('mode',4)==4, 'only triangle primitives supported'
   pos=accessor(p['attributes']['POSITION']);norm=accessor(p['attributes']['NORMAL']) if 'NORMAL' in p['attributes'] else [(0,1,0)]*len(pos);uv=accessor(p['attributes']['TEXCOORD_0']) if 'TEXCOORD_0' in p['attributes'] else [(0,0)]*len(pos)
   ids=[v[0] for v in accessor(p['indices'])] if 'indices' in p else list(range(len(pos)))
   start=len(block)
   for v,n,t in zip(pos,norm,uv):block.extend(struct.pack('<8f',v[0],v[1],-v[2],n[0],n[1],-n[2],t[0],t[1]))
   for i in range(0,len(ids),3):block.extend(struct.pack('<3I',ids[i],ids[i+2],ids[i+1]))
   primitives.append({'offset':start,'vertices':len(pos),'indices':len(ids),'material':p.get('material',-1)})
  meshes.append({'primitives':primitives})
 nodes=[]
 for i,n in enumerate(doc.get('nodes',[])):
  t=n.get('translation',[0,0,0]);q=n.get('rotation',[0,0,0,1]);sc=n.get('scale',[1,1,1]);matrix=n.get('matrix',[])
  if matrix:matrix=[v*(-1 if ((j%4==2) != (j//4==2)) else 1) for j,v in enumerate(matrix)]
  nodes.append({'name':n.get('name','node_'+str(i)),'mesh':n.get('mesh',-1),'children':n.get('children',[]),'position':[t[0],t[1],-t[2]],'rotation':[-q[0],-q[1],q[2],q[3]],'scale':sc,'matrix':matrix})
 header=json.dumps({'materials':mats,'meshes':meshes,'nodes':nodes,'roots':doc['scenes'][doc.get('scene',0)]['nodes']},separators=(',',':')).encode();output.parent.mkdir(parents=True,exist_ok=True);output.write_bytes(gzip.compress(b'GRM1'+struct.pack('<I',len(header))+header+block,compresslevel=9,mtime=0))
 return {'source':path.name,'output':output.name,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'nodes':len(nodes),'triangles':sum(p['indices']//3 for m in meshes for p in m['primitives']),'bytes':output.stat().st_size}
if __name__=='__main__':
 a=argparse.ArgumentParser();a.add_argument('input',type=pathlib.Path);a.add_argument('output',type=pathlib.Path);args=a.parse_args();reports=[]
 for p in sorted(args.input.glob('*.glb')):
  report=convert(p,args.output/(p.stem+'.grmesh'),args.output.parent/'Textures');reports.append(report);print(report)
 (args.output.parent/'geometry-manifest.json').write_text(json.dumps({'items':reports},indent=2))
