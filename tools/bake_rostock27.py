"""Bake official LAiV DGM5 with DGM1 at start into a 16m local grid. No invented ascent."""
import json,math,struct,hashlib,argparse
from pathlib import Path
import numpy as np,pyproj,rasterio
from scipy.ndimage import map_coordinates
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('dgm5');parser.add_argument('dgm1');args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
r=json.loads((root/'assets/data/routes.json').read_text())[16];lat,lon=r['coordinates'][0]
factor=111195*math.cos(math.radians(lat));first=np.array([(r['coordinates'][1][1]-lon)*factor,-(r['coordinates'][1][0]-lat)*111195]);rotation=math.atan2(-first[0],-first[1]);co,si=math.cos(rotation),math.sin(rotation)
metric=np.array([[(c[1]-lon)*factor,-(c[0]-lat)*111195] for c in r['coordinates']]);rotated=metric@np.array([[co,si],[-si,co]])
step=16;low=np.floor((rotated.min(axis=0)-600)/step)*step;high=np.ceil((rotated.max(axis=0)+600)/step)*step
xs=np.arange(low[0],high[0]+1,step);zs=np.arange(low[1],high[1]+1,step);X,Z=np.meshgrid(xs,zs);mx=X*co+Z*si;mz=-X*si+Z*co
T=pyproj.Transformer.from_crs(4326,25833,always_xy=True);E,N=T.transform(lon+mx/factor,lat-mz/111195)
def sample(path,E,N):
 with rasterio.open(path) as d:
  a=d.read(1);iv=~d.transform;cx=iv.a*E+iv.b*N+iv.c-.5;cy=iv.d*E+iv.e*N+iv.f-.5
  return map_coordinates(a,[cy,cx],order=1,mode='nearest'),(cx>=0)&(cy>=0)&(cx<a.shape[1]-1)&(cy<a.shape[0]-1)
h,valid=sample(args.dgm5,E,N)
assert valid.all(), 'grid must remain within official coverage'
h1,v1=sample(args.dgm1,E,N);h=np.where(v1,h1,h)
e0,n0=T.transform(lon,lat);base=float(sample(args.dgm1,np.array([e0]),np.array([n0]))[0][0]);h-=base
out=root/'assets/data';(out/'rostock_height27.bin').write_bytes(h.astype('<f4').tobytes())
meta={'source':'© GeoBasis-DE/M-V','service':'https://www.geodaten-mv.de/dienste/dgm_wcs','coverage':'mv_dgm5; mv_dgm at start','source_resolution_m':[5,1],'runtime_spacing_m':step,'vertical_reference':'DE_DHHN2016_NH EPSG:7837','baseline_nhn_m':base,'low':low.tolist(),'width':len(xs),'height':len(zs),'origin':[lat,lon],'rotation':rotation,'sha256':hashlib.sha256((out/'rostock_height27.bin').read_bytes()).hexdigest(),'retrieved':'2026-10-05','_assumption':True,'interpretation':'16m bilinear resampling; road centre profile at 5m; game reference zero at start, not survey of road surface'}
(out/'rostock_height27.json').write_text(json.dumps(meta,indent=2)+'\n')
# Actual initial route samples independently from original DGM.
s=0;profile=[]
for i,c in enumerate(r['coordinates']):
 if i:s+=np.linalg.norm(metric[i]-metric[i-1])
 e,n=T.transform(c[1],c[0]);value,v=sample(args.dgm1,np.array([e]),np.array([n]));
 if s<1500:profile.append([round(s,1),round(float(value[0])-base,2)])
print('grid',h.shape,'baseline',base,'initial profile',profile[:30])
